module Landrush
  module Cap
    module Linux
      module RedirectDns
        def self.redirect_dns(machine, target = {})
          dns_servers = machine.guest.capability(:configured_dns_servers)
          %w(tcp udp).each do |proto|
            dns_servers.each do |dns_server|
              machine.guest.capability(
                :add_iptables_rule,
                _redirect_dns_rule(proto, dns_server, target.fetch(:host), target.fetch(:port))
              )
            end
          end
        end

        def self._redirect_dns_rule(protocol, original_server, target_server, target_port)
          "OUTPUT -t nat -p #{protocol} -d #{original_server} --dport 53 -j DNAT --to-destination #{target_server}:#{target_port}"
        end
      end
    end
  end
end
