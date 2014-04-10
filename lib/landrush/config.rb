module Landrush
  class Config < Vagrant.plugin('2', :config)
    attr_accessor :hosts
    attr_accessor :upstream_servers
    attr_accessor :host_ip_address

    def initialize
      @hosts = {}
      @enabled = false
      @default_upstream = [[:udp, '8.8.8.8', 53], [:tcp, '8.8.8.8', 53]]
      @default_tld = 'vagrant.dev'
      @upstream_servers = @default_upstream
      @guest_redirect_dns = true
    end

    def enable(enabled=true)
      @enabled = true
    end

    def disable
      @enabled = false
    end

    def enabled?
      @enabled
    end

    def guest_redirect_dns=(guest_redirect_dns=true)
      @guest_redirect_dns=guest_redirect_dns
    end

    def guest_redirect_dns?
      @guest_redirect_dns
    end

    def host(hostname, ip_address=nil)
      @hosts[hostname] = ip_address
    end

    def tld
      @tld ||= @default_tld
    end

    def tld=(tld)
      @tld = tld
    end

    def upstream(ip, port=53, protocol=nil)
      if @upstream_servers == @default_upstream
        @upstream_servers = []
      end

      if !protocol
        @upstream_servers.push [:udp, ip, port]
        @upstream_servers.push [:tcp, ip, port]
      else
        @upstream_servers.push [protocol, ip, port]
      end
    end

    def merge(other)
      super.tap do |result|
        result.hosts = @hosts.merge(other.hosts)
      end
    end

    def validate(machine)
      if enabled?
        unless machine.config.vm.hostname.to_s.length > 0
          return { 'landrush' => ['you must specify a hostname so we can make a DNS entry for it'] }
        end
      end
      {}
    end
  end
end
