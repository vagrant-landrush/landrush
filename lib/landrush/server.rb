require 'rubydns'
require 'rexec/daemon'

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
      Landrush.config.transaction do
        @upstream_servers ||= Landrush.config['upstream']
      end
    end

    def self.interfaces
      [
        [:udp, "0.0.0.0", port],
        [:tcp, "0.0.0.0", port]
      ]
    end

    def self.upstream
      @upstream ||= RubyDNS::Resolver.new(upstream_servers)
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

        match(/.*/) do |transaction|
          type = transaction.resource_class.name.split('::').last.downcase
          host = Store.hosts.find(transaction.name, type)
          if host
            transaction.respond!(*Store.hosts.get(host, type), ttl: 0)
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
