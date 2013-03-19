module VagrantRubydns
  class Provisioner < Vagrant.plugin('2', :provisioner)
    def initialize(machine, config)
      super
    end

    def configure(root_config)
    end

    def ip_addresses
      @machine.config.vm.networks.map { |type, params|
        params if type == :private_network
      }.compact.map { |params| params[:ip] } 
    end

    def hostname
      @machine.config.vm.hostname
    end

    def provision
      puts "hi i am rubydns provisioner"
      puts "i wanna set #{ip_addresses.inspect} to #{hostname}"
    end
  end
end
