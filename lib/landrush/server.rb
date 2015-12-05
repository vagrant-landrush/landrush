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
      # Doing collect to cast protocol to symbol because JSON store doesn't know about symbols
      @upstream_servers ||= Store.config.get('upstream').collect {|i| [i[0].to_sym, i[1], i[2]]}
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

    def self.check_a_record (host, transaction)
      value = Store.hosts.get(host)
      if (IPAddr.new(value) rescue nil)
        name = transaction.name =~ /#{host}/ ? transaction.name : host
        transaction.respond!(value, {ttl: 0, name: name})
      else
        transaction.respond!(Name.create(value), resource_class: IN::CNAME, ttl: 0)
        check_a_record(value, transaction)
      end
    end

    def self.run
      server = self
      RubyDNS::run_server(listen: interfaces) do
        self.logger.level = Logger::INFO

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
          transaction.passthrough!(server.upstream)
        end
      end
    end
  end
end
