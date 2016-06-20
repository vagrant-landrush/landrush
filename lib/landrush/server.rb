require 'rubydns'
require 'ipaddr'
require "vagrant/util/platform"

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
      @upstream_servers ||= Store.config.get('upstream').collect {|i| [i[0].to_sym, i[1], i[2]]}
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
      if Vagrant::Util::Platform.windows?
        # Need to handle Windows differently. Kernel.spawn fails to work, if the shell creating the process is closed.
        # See https://github.com/vagrant-landrush/landrush/issues/199
        info = Process.create(:command_line => "ruby #{__FILE__} #{port} #{working_dir}",
                              :creation_flags => Process::DETACHED_PROCESS,
                              :process_inherit => false,
                              :thread_inherit => true,
                              :cwd => working_dir.to_path)
        pid = info.process_id
      else
        pid = spawn('ruby', __FILE__, port.to_s, working_dir.to_s, :chdir => working_dir.to_path, :pgroup => true)
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
      IO.read(pid_file).to_i rescue nil
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
        !!Process.kill(0, pid) rescue false
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
      run_dns_server(:listen => interfaces, :logger => @logger) do
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
        trap("INT") do
          EventMachine.stop
        end

        server.run(options)
      end

      server.fire(:stop)
    end

    def self.check_a_record(host, transaction)
      value = Store.hosts.get(host)
      if value.nil?
        return
      end

      if (IPAddr.new(value) rescue nil)
        name = transaction.name =~ /#{host}/ ? transaction.name : host
        transaction.respond!(value, :ttl => 0, :name => name)
      else
        transaction.respond!(Name.create(value), resource_class: IN::CNAME, ttl: 0)
        check_a_record(value, transaction)
      end
    end

    # private methods
    def self.write_pid(pid)
      ensure_path_exits(pid_file)
      File.open(pid_file, 'w') {|f| f << pid.to_s}
    end

    def self.read_pid
      IO.read(pid_file).to_i rescue nil
    end

    def self.delete_pid_file
      if File.exist? pid_file
        FileUtils.rm(pid_file)
      end
    end

    def self.pid_file
      File.join(working_dir, 'run', 'landrush.pid')
    end

    def self.process_status
      if File.exist? pid_file
        return running? ? :running : :unknown
      else
        return :stopped
      end
    end

    def self.ensure_path_exits(file_name)
      dirname = File.dirname(file_name)
      unless File.directory?(dirname)
        FileUtils.mkdir_p(dirname)
      end
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

    private_class_method :write_pid, :read_pid, :delete_pid_file, :pid_file, :process_status, :ensure_path_exits,
                         :terminate_process
  end
end

# Only run the following code when this file is the main file being run
# instead of having been required or loaded by another file
if __FILE__ == $0
  # TODO, Add some argument checks
  Landrush::Server.run(ARGV[0], ARGV[1])
end
