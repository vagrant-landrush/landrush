require 'rubydns'

module Landrush
  class Server < RExec::Daemon::Base
    Name = Resolv::DNS::Name
    IN   = Resolv::DNS::Resource::IN

    def self.port
      @port ||= 10053
    end

    def self.port=(port)
      @port = port
    end

    def self.upstream_servers
      [[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]]
    end

    def self.interfaces
      [
        [:udp, "0.0.0.0", port],
        [:tcp, "0.0.0.0", port]
      ]
    end

    def self.upstream
      @upstream ||= landrush::Resolver.new(upstream_servers)
    end

    def self.pid
      RExec::Daemon::ProcessFile.recall(self)
    end

    # For RExec
    def self.working_directory
      Landrush.working_dir
    end

    def self.running?
      RExec::Daemon::ProcessFile.status(self) == :running
    end

    def self.prefork
      super
    end

    def self.run
      server = self
      RubyDNS::run_server(:listen => interfaces) do
        self.logger.level = Logger::INFO
        
        match(/.*/, IN::A) do |transaction|
          ip = Store.hosts.get(transaction.name)
          if ip
            transaction.respond!(ip)
          else
            transaction.passthrough!(server.upstream)
          end
        end

        # Default DNS handler
        otherwise do |transaction|
          transaction.passthrough!(server.upstream)
        end
      end
    end
  end
end
