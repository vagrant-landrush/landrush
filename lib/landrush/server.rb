require 'filelock'
require 'win32/process' unless (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM).nil? # only require on Windows
require_relative 'store'
require_relative 'util/path'
require_relative 'util/process_helper'
require_relative 'dns_server'

module Landrush
  class Server
    extend Landrush::Util::ProcessHelper
    extend Landrush::DnsServer

    class << self
      attr_reader :gems_dir
      attr_reader :ui
      attr_writer :ui
      attr_writer :port

      def gems_dir=(gems_dir)
        @gems_dir = Pathname(gems_dir)
      end

      def working_dir
        # TODO, https://github.com/vagrant-landrush/landrush/issues/178
        # Due to the fact that the whole server is just a bunch of static methods,
        # there is no initialize method to ensure that the working directory is
        # set prior to making calls to this method. Things work, since at the appropriate
        # Vagrant plugin integration points (e.g. setup.rb) we set the working dir based
        # on the environment passed to us.
        if @working_dir.nil?
          raise 'The Server\s working directory needs to be explicitly set prior to calling this method'
        end
        @working_dir
      end

      def working_dir=(working_dir)
        @working_dir = Pathname(working_dir).tap(&:mkpath)
        @log_file = File.join(working_dir, 'log', 'landrush.log')
        ensure_path_exits(@log_file)
        @logger = setup_logging
        @pid_file = File.join(working_dir, 'run', 'landrush.pid')
        ensure_path_exits(@pid_file)
      end

      def port
        return @port unless @port.nil?
        if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM).nil?
          # Default Landrush port for non Windows OS
          100_53
        else
          # On Windows we need to use the default DNS port, since there seems to be no way to configure it otherwise
          53
        end
      end

      # Used to start the Landrush DNS server as a child process using ChildProcess gem
      def start
        with_pid_lock do |file|
          # Check if the daemon is already started...
          if running?(file)
            @ui.info "[landrush] DNS server already running with pid #{read_pid(file)}" unless @ui.nil?
            return
          end

          # On a machine with just Vagrant installed there might be no other Ruby except the
          # one bundled with Vagrant. Let's make sure the embedded bin directory containing
          # the Ruby executable is added to the PATH.
          Landrush::Util::Path.ensure_ruby_on_path

          ruby_bin = Landrush::Util::Path.embedded_vagrant_ruby.nil? ? 'ruby' : Landrush::Util::Path.embedded_vagrant_ruby
          start_server_script = Pathname(__dir__).join('start_server.rb').to_s
          @ui.detail("[landrush] starting DNS server: '#{ruby_bin} #{start_server_script} #{port} #{working_dir} #{gems_dir}'") unless @ui.nil?
          if Vagrant::Util::Platform.windows?
            # Need to handle Windows differently. Kernel.spawn fails to work, if
            # the shell creating the process is closed.
            # See https://github.com/vagrant-landrush/landrush/issues/199
            #
            # Note to the Future: Windows does not have a
            # file handle inheritance issue like Linux and Mac (see:
            # https://github.com/vagrant-landrush/landrush/issues/249)
            #
            # On windows, if no filehandle is passed then no files get
            # inherited by default, but if any filehandle is passed to
            # a spawned process then all files that are
            # set as inheritable will get inherited. In another project this
            # created a problem (see: https://github.com/dustymabe/vagrant-sshfs/issues/41).
            #
            # Today we don't pass any filehandles, so it isn't a problem.
            # Future self, make sure this doesn't become a problem.
            info = Process.create(command_line:    "#{ruby_bin} #{start_server_script} #{port} #{working_dir} #{gems_dir}",
                                  creation_flags:  Process::DETACHED_PROCESS,
                                  process_inherit: false,
                                  thread_inherit:  true,
                                  cwd:             working_dir.to_path)
            pid = info.process_id
          else
            # Fix https://github.com/vagrant-landrush/landrush/issues/249)
            # by turning of filehandle inheritance with :close_others => true
            # and by explicitly closing STDIN, STDOUT, and STDERR
            pid = spawn(ruby_bin, start_server_script, port.to_s, working_dir.to_s, gems_dir.to_s,
                        in:           :close,
                        out:          :close,
                        err:          :close,
                        close_others: true,
                        chdir:        working_dir.to_path,
                        pgroup:       true)
            Process.detach pid
          end

          write_pid(pid, file)
          # As of Vagrant 1.8.6 this additional sleep is needed, otherwise the child process dies!?
          sleep 1
        end
      end

      def stop
        with_pid_lock do |file|
          puts 'Stopping daemon...'

          # Check if the daemon is already stopped...
          unless running?(file)
            return
          end

          terminate_process(file)

          # If after doing our best the daemon is still running (pretty odd)...
          if running?(file)
            puts 'Daemon appears to be still running!'
            return
          end

          # Otherwise the daemon has been stopped.
          write_pid('', file)
        end
      end

      def restart
        stop
        start
      end

      def status
        with_pid_lock do |file|
          process_status(file)
        end
      end

      def pid
        with_pid_lock do |file|
          read_pid(file)
        end
      end

      def run(port, working_dir)
        server = self
        server.port = port
        server.working_dir = working_dir
        
        DnsServer.start_dns_server(@logger)
      end

      private

      def running?(file)
        pid = read_pid(file)
        return false if pid.nil? || pid.zero?
        if Vagrant::Util::Platform.windows?
          begin
            Process.get_exitcode(pid).nil?
          rescue SystemCallError => e
            # Need to handle this explicitly since this error gets thrown in case we call get_exitcode with a stale pid
            raise e unless e.class.name.start_with?('Errno::ENXIO')
          end
        else
          begin
            !!Process.kill(0, pid)
          rescue StandardError
            false
          end
        end
      end

      def setup_logging
        log_file = File.open(@log_file, 'w')
        log_file.sync = true
        logger = Logger.new(log_file)

        case ENV.fetch(:LANDRUSH_LOG.to_s) { 'info' }
        when 'debug'
          logger.level = Logger::DEBUG
        when 'info'
          logger.level = Logger::INFO
        when 'warn'
          logger.level = Logger::WARN
        when 'error'
          logger.level = Logger::ERROR
        when 'fatal'
          logger.level = Logger::FATAL
        when 'unknown'
          logger.level = Logger::UNKNOWN
        else
          raise ArgumentError, "invalid log level: #{severity}"
        end
        logger
      end

      def with_pid_lock
        Filelock @pid_file, wait: 60 do |file|
          yield file
        end
      rescue Filelock::WaitTimeout
        raise ConfigLockError, 'Unable to lock pid file.'
      end
    end
  end
end
