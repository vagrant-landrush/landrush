module Landrush
  module Action
    class Setup
      include Common

      def call(env)
        handle_action_stack(env) do
          pre_boot_setup if enabled?
        end

        # This is after the middleware stack returns, which, since we're right
        # before the Network action, should mean that all interfaces are good
        # to go.
        record_machine_dns_entry if enabled?
      end

      def pre_boot_setup
        record_dependent_vm
        add_prerequisite_network_interface
        start_server
        setup_static_dns
      end

      def record_dependent_vm
        DependentVMs.add(machine_hostname)
      end

      def add_prerequisite_network_interface
        return unless virtualbox? && !private_network_exists?

        info 'virtualbox requires an additional private network; adding it'
        machine.config.vm.network :private_network, type: :dhcp
      end

      def start_server
        return if Server.running?

        info 'starting dns server'
        Server.start
      end

      def setup_static_dns
        global_config.landrush.hosts.each do |hostname, dns_value|
          info "adding static entry: #{hostname} => #{dns_value}"
          Store.hosts.set hostname, dns_value
	  Store.hosts.set("#{dns_value.split('.').reverse.join('.')}.in-addr.arpa.", hostname)
        end
      end

      def record_machine_dns_entry
        ip_address = machine.guest.capability(:read_host_visible_ip_address)

        info "adding machine entry: #{machine_hostname} => #{ip_address}"

        Store.hosts.set(machine_hostname, ip_address)
	Store.hosts.set("#{ip_address.split('.').reverse.join('.')}.in-addr.arpa.", machine_hostname)
      end

      def private_network_exists?
        machine.config.vm.networks.any? { |type, _| type == :private_network }
      end
    end
  end
end
