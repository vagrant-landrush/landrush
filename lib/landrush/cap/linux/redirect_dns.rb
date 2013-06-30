module Landrush
  module Cap
    module Linux
      module RedirectDns
        def self.redirect_dns(machine, target={})
          %w[tcp udp].each do |proto|
            machine.guest.capability(
              :add_iptables_rule,
              _redirect_dns_rule(proto, _current(machine), target.fetch(:host), target.fetch(:port))
            )
          end
        end

        def self._current(machine)
          machine.guest.capability(:configured_dns_server)
        end

        def self._redirect_dns_rule(protocol, original_server, target_server, target_port)
          "OUTPUT -t nat -p #{protocol} -d #{original_server} --dport 53 -j DNAT --to-destination #{target_server}:#{target_port}"
        end
      end
    end
  end
end

