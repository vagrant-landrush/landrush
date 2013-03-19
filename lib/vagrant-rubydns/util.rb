module VagrantRubydns
  module Util
    def self.host_and_ip(machine)
      [hostname(machine), ip_address(machine)]
    end

    def self.hostname(machine)
      return nil unless machine

      machine.config.vm.hostname
    end

    def self.ip_address(machine)
      return nil unless machine

      machine.config.vm.networks.each do |type, options|
        if type == :private_network && options[:ip].is_a?(String)
          return options[:ip]
        end
      end

      nil
    end
  end
end
