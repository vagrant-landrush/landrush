module Landrush
  class Config < Vagrant.plugin('2', :config)
    attr_accessor :hosts
    attr_accessor :enabled
    attr_accessor :tld
    attr_accessor :upstream_servers
    attr_accessor :host_ip_address
    attr_accessor :guest_redirect_dns
    attr_accessor :host_interface
    attr_accessor :host_interface_class
    attr_accessor :host_interface_excludes
    attr_accessor :host_redirect_dns

    INTERFACE_CLASSES = [:any, :ipv4, :ipv6].freeze
    INTERFACE_CLASS_INVALID = "Invalid interface class, should be one of: #{INTERFACE_CLASSES.join(', ')}".freeze

    DEFAULTS = {
      enabled:                 false,
      tld:                     'vagrant.test',
      upstream_servers:        [[:udp, '8.8.8.8', 53], [:tcp, '8.8.8.8', 53]],
      host_ip_address:         nil,
      guest_redirect_dns:      true,
      host_interface:          nil,
      host_interface_excludes: [/lo[0-9]*/, /docker[0-9]+/, /tun[0-9]+/],
      host_interface_class:    :ipv4,
      host_redirect_dns:       true
    }.freeze

    def initialize
      @hosts                     = {}
      @enabled                   = UNSET_VALUE
      @tld                       = UNSET_VALUE
      @upstream_servers          = UNSET_VALUE
      @host_ip_address           = UNSET_VALUE
      @guest_redirect_dns        = UNSET_VALUE
      @host_interface            = UNSET_VALUE
      @host_interface_excludes   = UNSET_VALUE
      @host_interface_class      = UNSET_VALUE
      @host_redirect_dns         = UNSET_VALUE
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

    def host_redirect_dns?
      @host_redirect_dns
    end

    def host(hostname, ip_address = nil)
      @hosts[hostname] = ip_address
    end

    def upstream(ip, port = 53, protocol = nil)
      @upstream_servers = [] if @upstream_servers == UNSET_VALUE

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

    def validate(_machine)
      errors = _detected_errors
      errors.concat validate_host_interface_class

      { 'landrush' => errors }
    end

    def validate_host_interface_class
      @host_interface_class = @host_interface_class.intern if @host_interface_class.is_a? String

      return [] if INTERFACE_CLASSES.include? @host_interface_class

      # TODO: Should really be using I18n; makes testing a lot cleaner too.
      [INTERFACE_CLASS_INVALID, fields: 'host_interface_class']
    end
  end
end
