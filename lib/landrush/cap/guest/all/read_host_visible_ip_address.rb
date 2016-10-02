module Landrush
  module Cap
    module All
      module ReadHostVisibleIpAddress
        def self.filter_addresses(addresses)
          unless @machine.config.landrush.host_interface_excludes.nil?
            re = Regexp.union(@machine.config.landrush.host_interface_excludes)

            addresses = addresses.select do |addr|
              !addr['name'].match(re)
            end
          end

          addresses
        end

        def self.filter_preferred_addresses(addresses)
          if @machine.config.landrush.host_interface_class == :any
            addresses = addresses.select do |addr|
              (addr.key?('ipv4') && !addr['ipv4'].empty?) ||
                (addr.key?('ipv6') && !addr['ipv6'].empty?)
            end
          else
            key = @machine.config.landrush.host_interface_class.to_s

            addresses = addresses.select do |addr|
              (addr.key?(key) && !addr[key].empty?)
            end
          end

          addresses
        end

        def self.read_host_visible_ip_address(machine)
          @machine = machine

          addr      = nil
          addresses = machine.guest.capability(:landrush_ip_get)

          # Short circuit this one first: if an explicit interface is defined, look for it and return it if found.
          # Technically, we could do a single loop, but execution time is not vital here.
          # This allows us to be more accurate, especially with logging what's going on.
          unless machine.config.landrush.host_interface.nil?
            addr = addresses.detect { |a| a['name'] == machine.config.landrush.host_interface }

            machine.env.ui.warn "[landrush] Unable to find interface #{machine.config.landrush.host_interface}" if addr.nil?
          end

          if addr.nil?
            addresses = filter_addresses addresses
            raise 'No addresses found' if addresses.empty?

            addresses = filter_preferred_addresses addresses
            raise 'No addresses found' if addresses.empty?

            addr = addresses.last
          end

          # Keep preferring IPv4 over IPv6.
          key = if machine.config.landrush.host_interface_class == :any
                  addr['ipv4'].empty? ? 'ipv6' : 'ipv4'
                else
                  machine.config.landrush.host_interface_class.to_s
                end

          ip = IPAddr.new(addr[key])

          machine.env.ui.info "[landrush] Using #{addr['name']} (#{addr[key]})"

          ip.to_s
        end
      end
    end
  end
end
