require 'rubydns'
require 'ipaddr'
require 'vagrant/util/platform'

require_relative 'store'

module Landrush
  class Server
    Name = Resolv::DNS::Name
    IN   = Resolv::DNS::Resource::IN

    def self.working_dir
      # TODO, https://github.com/vagrant-landrush/landrush/issues/178
      # Due to the fact that the whole server is just a bunch of static methods,
      # there is no initalize method to ensure that the working directory is
      # set prior to making calls to this method. Things work, since at the appropriate
      # Vagrant plugin integrtion points (e.g. setup.rb) we set the working dir based
      # on the enviroment passed to us.
      if @working_dir.nil?
        raise 'The Server\s working directory needs to be explicitly set prior to calling this method'
      end
      @working_dir
    end

    def self.working_dir=(working_dir)
      @working_dir = Pathname(working_dir).tap(&:mkpath)
    end

    def self.log_directory
      File.join(working_dir, 'log')
    end

    def self.log_file_path
      File.join(log_directory, 'landrush.log')
    end

    def self.port
      if Vagrant::Util::Platform.windows?
        # On Windows we need to use the default DNS port, since there seems to be no way to configure it otherwise
        @port ||= 53
      else
        @port ||= 100_53
      end
    end

    def self.port=(port)
      @port = port
    end

    def self.upstream_servers
      # Doing collect to cast protocol to symbol because JSON store doesn't know about symbols
      @upstream_servers ||= Store.config.get('upstream').collect { |i| [i[0].to_sym, i[1], i[2]] }
    end

    def self.interfaces
      [
        [:udp, '0.0.0.0', port],
        [:tcp, '0.0.0.0', port]
      ]
    end

    def self.upstream
      @upstream ||= RubyDNS::Resolver.new(upstream_servers)
    end

    # Used to start the Landrush DNS server as a child process using ChildProcess gem
    def self.start
      ensure_ruby_on_path
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
        # created a problem (see:
        # https://github.com/dustymabe/vagrant-sshfs/issues/41).
        #
        # Today we don't pass any filehandles, so it isn't a problem.
        # Future self, make sure this doesn't become a problem.

        info = Process.create(command_line:    "ruby #{__FILE__} #{port} #{working_dir}",
                              creation_flags:  Process::DETACHED_PROCESS,
                              process_inherit: false,
                              thread_inherit:  true,
                              cwd:             working_dir.to_path)
        pid = info.process_id
      else
        # Fix https://github.com/vagrant-landrush/landrush/issues/249)
        # by turning of filehandle inheritance with :close_others => true
        # and by explicitly closing STDIN, STDOUT, and STDERR

        pid = spawn('ruby', __FILE__, port.to_s, working_dir.to_s,
                    in:           :close,
                    out:          :close,
                    err:          :close,
                    close_others: true,
                    chdir:        working_dir.to_path,
                    pgroup:       true)
        Process.detach pid
      end

      write_pid(pid)
    end

    def self.stop
      puts 'Stopping daemon...'

      # Check if the pid file exists...
      unless File.file?(pid_file)
        puts "Pid file #{pid_file} not found. Is the daemon running?"
        return
      end

      pid = read_pid

      # Check if the daemon is already stopped...
      unless running?
        puts "Pid #{pid} is not running. Has daemon crashed?"
        return
      end

      terminate_process pid

      # If after doing our best the daemon is still running (pretty odd)...
      if running?
        puts 'Daemon appears to be still running!'
        return
      end

      # Otherwise the daemon has been stopped.
      delete_pid_file
    end

    def self.restart
      stop
      start
    end

    def self.pid
      IO.read(pid_file).to_i
    rescue
      nil
    end

    def self.running?
      pid = read_pid
      return false if pid.nil?
      if Vagrant::Util::Platform.windows?
        begin
          Process.get_exitcode(pid).nil?
        # Need to handle this explicitly since this error gets thrown in case we call get_exitcode with a stale pid
        rescue SystemCallError => e
          raise e unless e.class.name.start_with?('Errno::ENXIO')
        end
      else
        begin
          !!Process.kill(0, pid)
        rescue
          false
        end
      end
    end

    def self.status
      case process_status
      when :running
        puts "Daemon status: running pid=#{read_pid}"
      when :stopped
        puts 'Daemon status: stopped'
      else
        puts 'Daemon status: unknown'
        puts "#{pid_file} exists, but process is not running"
        puts "Check log file: #{log_file_path}"
      end
    end

    def self.run(port, working_dir)
      server = self
      server.port = port
      server.working_dir = working_dir

      ensure_path_exits(log_file_path)
      log_file = File.open(log_file_path, 'w')
      log_file.sync = true
      @logger = Logger.new(log_file)
      @logger.level = Logger::INFO

      # Start the DNS server
      run_dns_server(listen: interfaces, logger: @logger) do
        match(/.*/, IN::A) do |transaction|
          host = Store.hosts.find(transaction.name)
          if host
            server.check_a_record(host, transaction)
          else
            transaction.passthrough!(server.upstream)
          end
        end

        match(/.*/, IN::PTR) do |transaction|
          host = Store.hosts.find(transaction.name)
          if host
            transaction.respond!(Name.create(Store.hosts.get(host)))
          else
            transaction.passthrough!(server.upstream)
          end
        end

        # Default DNS handler
        otherwise do |transaction|
          # @logger.info "Passing on to upstream: #{transaction.to_s}"
          transaction.passthrough!(server.upstream)
        end
      end
    end

    def self.run_dns_server(options = {}, &block)
      server = RubyDNS::RuleBasedServer.new(options, &block)

      EventMachine.run do
        trap('INT') do
          EventMachine.stop
        end

        server.run(options)
      end

      server.fire(:stop)
    end

    def self.check_a_record(host, transaction)
      value = Store.hosts.get(host)
      return if value.nil?

      if begin
            IPAddr.new(value)
          rescue
            nil
          end
        name = transaction.name =~ /#{host}/ ? transaction.name : host
        transaction.respond!(value, ttl: 0, name: name)
      else
        transaction.respond!(Name.create(value), resource_class: IN::CNAME, ttl: 0)
        check_a_record(value, transaction)
      end
    end

    # private methods
    def self.write_pid(pid)
      ensure_path_exits(pid_file)
      File.open(pid_file, 'w') { |f| f << pid.to_s }
    end

    def self.read_pid
      IO.read(pid_file).to_i
    rescue
      nil
    end

    def self.delete_pid_file
      FileUtils.rm(pid_file) if File.exist? pid_file
    end

    def self.pid_file
      File.join(working_dir, 'run', 'landrush.pid')
    end

    def self.process_status
      return running? ? :running : :unknown if File.exist? pid_file
      :stopped
    end

    def self.ensure_path_exits(file_name)
      dirname = File.dirname(file_name)
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    end

    def self.terminate_process(pid)
      # Kill/Term loop - if the daemon didn't die easily, shoot
      # it a few more times.
      attempts = 5
      while running? && attempts > 0
        sig = (attempts >= 2) ? 'KILL' : 'TERM'

        puts "Sending #{sig} to process #{pid}..."
        Process.kill(sig, pid)

        attempts -= 1
        sleep 1
      end
    end

    # On a machine with just Vagrant installed there might be no other Ruby except the
    # one bundled with Vagrant. Let's make sure the embedded bin directory containing
    # the Ruby executable is added to the PATH.
    def self.ensure_ruby_on_path
      vagrant_binary = Vagrant::Util::Which.which('vagrant')
      vagrant_binary = File.realpath(vagrant_binary) if File.symlink?(vagrant_binary)
      # in a Vagrant installation the Ruby executable is in ../embedded/bin relative to the vagrant executable
      # we don't use File.join here, since even on Cygwin we want a Windows path - see https://github.com/vagrant-landrush/landrush/issues/237
      separator = if Vagrant::Util::Platform.windows?
                    '\\'
                  else
                    '/'
                  end
      embedded_bin_dir = File.dirname(File.dirname(vagrant_binary)) + separator + 'embedded' + separator + 'bin'
      ENV['PATH'] = embedded_bin_dir + File::PATH_SEPARATOR + ENV['PATH'] if File.exist?(embedded_bin_dir)
    end

    private_class_method :write_pid, :read_pid, :delete_pid_file, :pid_file, :process_status, :ensure_path_exits,
                         :terminate_process, :ensure_ruby_on_path
  end
end

# Only run the following code when this file is the main file being run
# instead of having been required or loaded by another file
if __FILE__ == $PROGRAM_NAME
  # TODO, Add some argument checks
  Landrush::Server.run(ARGV[0], ARGV[1])
end
