module Landrush
  class Config < Vagrant.plugin('2', :config)
    attr_accessor :hosts
    attr_accessor :enabled
    attr_accessor :tld
    attr_accessor :upstream_servers
    attr_accessor :host_ip_address
    attr_accessor :guest_redirect_dns

    DEFAULTS = {
      :enabled => false,
      :tld => 'vagrant.dev',
      :upstream_servers => [[:udp, '8.8.8.8', 53], [:tcp, '8.8.8.8', 53]],
      :host_ip_address => nil,
      :guest_redirect_dns => true
    }

    def initialize
      @hosts = {}
      @enabled = UNSET_VALUE
      @tld = UNSET_VALUE
      @upstream_servers = UNSET_VALUE
      @host_ip_address = UNSET_VALUE
      @guest_redirect_dns = UNSET_VALUE
    end

    def enable
      @enabled = true
    end

    def disable
      @enabled = false
    end

    def enabled?
      !!@enabled
    end

    def guest_redirect_dns?
      @guest_redirect_dns
    end

    def host(hostname, ip_address=nil)
      @hosts[hostname] = ip_address
    end

    def upstream(ip, port=53, protocol=nil)
      if @upstream_servers == UNSET_VALUE
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

    def finalize!
      DEFAULTS.each do |name, value|
        if instance_variable_get('@' + name.to_s) == UNSET_VALUE
          instance_variable_set '@' + name.to_s, value
        end
      end
    end

    def validate(machine)
      errors = _detected_errors
      { 'landrush' => errors }
    end
  end
end
