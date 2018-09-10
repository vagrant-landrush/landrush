require 'rubydns'
require 'ipaddr'
require_relative 'store'

module Landrush
  module DnsServer
    Name = Resolv::DNS::Name
    IN   = Resolv::DNS::Resource::IN

    def self.interfaces
      [[:udp, '0.0.0.0', Server.port], [:tcp, '0.0.0.0', Server.port]]
    end

    def self.upstream_servers
      # Doing collect to cast protocol to symbol because JSON store doesn't know about symbols
      @upstream_servers ||= Store.config.get('upstream').collect { |i| [i[0].to_sym, i[1], i[2]] }
    end

    def self.upstream
      @upstream ||= RubyDNS::Resolver.new(upstream_servers, logger: @logger)
    end

    def self.start_dns_server(logger)
      @logger = logger
      run_dns_server(listen: interfaces, logger: logger) do
        match(/.*/, IN::A) do |transaction|
          host = Store.hosts.find(transaction.name)
          if host
            DnsServer.check_a_record(host, transaction)
          else
            transaction.passthrough!(DnsServer.upstream)
          end
        end

        match(/.*/, IN::PTR) do |transaction|
          host = Store.hosts.find(transaction.name)
          if host
            transaction.respond!(Name.create(Store.hosts.get(host)))
          else
            transaction.passthrough!(DnsServer.upstream)
          end
        end

        # Default DNS handler
        otherwise do |transaction|
          transaction.passthrough!(DnsServer.upstream)
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
         rescue StandardError
           nil
         end
        name = transaction.name =~ /#{host}/ ? transaction.name : host
        transaction.respond!(value, ttl: 0, name: name)
      else
        transaction.respond!(Name.create(value), resource_class: IN::CNAME, ttl: 0)
        DnsServer.check_a_record(value, transaction)
      end
    end
  end
end
