module VagrantRubydns
  module Util
    def self.hostname(env)
      return nil unless env[:machine]

      env[:machine].config.vm.hostname
    end

    def self.ip_address(env)
      return nil unless env[:machine]

      env[:machine].config.vm.networks.each do |type, options|
        if type == :private_network && options[:ip].is_a?(String)
          return options[:ip]
        end
      end

      nil
    end
  end
end
