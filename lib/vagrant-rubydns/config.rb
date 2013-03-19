module VagrantRubydns
  class Config < Vagrant.plugin('2', :config)
    attr_accessor :hosts

    def initialize
      @hosts = {}
    end

    def host(hostname, ip_address)
      @hosts[hostname] = ip_address
    end

    def merge(other)
      super.tap do |result|
        result.hosts = @hosts.merge(other.hosts)
      end
    end
  end
end
