module Landrush
  module Action
    class Setup
      include Common

      def call(env)
        # Make sure we use the right data directory for Landrush
        # Seems Vagrant only makes home_path available in this case, compared to custom commands where there is also data_dir
        Server.working_dir = File.join(env[:home_path], 'data', 'landrush')
        Server.gems_dir = File.join(env[:gems_path].to_s, 'gems')
        Server.ui = env[:ui]

        pre_boot_setup if enabled?
        app.call(env)
        # This is after the middleware stack returns, which, since we're right
        # before the Network action, should mean that all interfaces are good
        # to go.
        post_boot_setup if enabled?
      end

      def host_ip_address
        if private_network_ips.include? machine.config.landrush.host_ip_address
          machine.config.landrush.host_ip_address
        else
          machine.guest.capability(:read_host_visible_ip_address)
        end
      end

      private

      def pre_boot_setup
        add_prerequisite_network_interface
      end

      def post_boot_setup
        record_dependent_vm
        configure_server
        record_machine_dns_entry
        setup_static_dns
        start_server
        return unless machine.config.landrush.host_redirect_dns?
        env[:host].capability(:configure_visibility_on_host, host_ip_address, config.tld)
      end

      def record_dependent_vm
        DependentVMs.add(machine_hostname)
      end

      def add_prerequisite_network_interface
        return unless virtualbox? && !private_network_exists?

        info 'virtualbox requires an additional private network; adding it'
        machine.config.vm.network :private_network, type: :dhcp
      end

      def configure_server
        Store.config.set('upstream', config.upstream_servers)
      end

      def start_server
        return if Server.running?
        info 'starting dns server'
        Server.start
      end

      def setup_static_dns
        config.hosts.each do |hostname, dns_value|
          dns_value ||= host_ip_address
          next if Store.hosts.has?(hostname, dns_value)
          info "adding static DNS entry: #{hostname} => #{dns_value}"
          Store.hosts.set hostname, dns_value
          next unless ip_address?(dns_value)
          reverse_dns = IPAddr.new(dns_value).reverse
          info "adding static reverse DNS entry: #{reverse_dns} => #{dns_value}"
          Store.hosts.set(reverse_dns, hostname)
        end
      end

      def ip_address?(value)
        !(value =~ Resolv::IPv4::Regex).nil?
      end

      def record_machine_dns_entry
        ip_address = machine.config.landrush.host_ip_address || host_ip_address

        unless machine_hostname.match(config.tld)
          log :error, "hostname #{machine_hostname} does not match the configured TLD: #{config.tld}"
          log :error, "You will not be able to access #{machine_hostname} from the host"
        end

        unless Store.hosts.has?(machine_hostname, ip_address)
          info "adding machine entry: #{machine_hostname} => #{ip_address}"
          Store.hosts.set(machine_hostname, ip_address)
          Store.hosts.set(IPAddr.new(ip_address).reverse, machine_hostname)
        end
      end

      def private_network_exists?
        machine.config.vm.networks.any? { |type, _| type == :private_network }
      end

      # @return [Array<String] IPv4 addresses of all private networks
      def private_network_ips
        # machine.config.vm.networks is an array of two elements. The first containing the type as symbol, the second is a
        # hash containing other config data which varies between types
        machine.config.vm.networks.select { |network| :private_network == network[0] && !network[1][:ip].nil? }
               .map { |network| network[1][:ip] }
      end
    end
  end
end
