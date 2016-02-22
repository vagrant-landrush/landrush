require 'rubydns'
require 'ipaddr'
require_relative 'store'
require_relative 'os'

module Landrush
  class Server
    include Landrush::OS

    Name = Resolv::DNS::Name
    IN   = Resolv::DNS::Resource::IN

    def self.working_dir
      if @working_dir.nil?
        fail 'The working directory for the server needs to be explicitly set'
      end
      @working_dir
    end

    def self.working_dir=(working_dir)
      @working_dir = Pathname(working_dir).tap(&:mkpath)
    end

    def self.log_directory
      File.join(working_dir, 'log')
    end

    def self.log_file
      File.join(log_directory, 'landrush.log')
    end

    def self.port
      if OS.windows?
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
      ensure_path_exits(log_file)

      if OS.windows?
        pid = spawn('ruby', __FILE__, port.to_s, working_dir.to_s, :chdir => working_dir.to_path, [:out, :err] => [log_file, "w"], :new_pgroup => true)
      else
        pid = spawn('ruby', __FILE__, port.to_s, working_dir.to_s, :chdir => working_dir.to_path, [:out, :err] => [log_file, "w"], :pgroup => true)
      end
      Process.detach pid

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
      !!Process.kill(0, pid) rescue false
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
          puts "Check log file: #{log_file}"
      end
    end

    def self.run(port, working_dir)
      server = self
      server.port = port
      server.working_dir = working_dir

      # Start the DNS server
      RubyDNS.run_server(:listen => interfaces) do
        @logger.level = Logger::INFO

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
      Process.kill("INT", pid)
      sleep 0.1

      sleep 1 if running?

      # Kill/Term loop - if the daemon didn't die easily, shoot
      # it a few more times.
      attempts = 5
      while running? && attempts > 0
        sig = (attempts >= 2) ? "KILL" : "TERM"

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
