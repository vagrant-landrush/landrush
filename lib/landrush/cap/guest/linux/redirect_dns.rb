module Landrush
  module Cap
    module Linux
      module RedirectDns
        class << self
          def redirect_dns(machine, target = {})
            prefix_ui = Vagrant::UI::Prefixed.new(machine.env.ui, machine.name)
            dns_servers = machine.guest.capability(:configured_dns_servers)
            dns_servers.each do |dns_server|
              prefix_ui.info("[landrush] Setting up iptables rule on guest for DNS server #{dns_server}")
              enable_route_localnet(machine) if dns_server =~ /127\.0\.0\.\d+/
              %w[tcp udp].each do |proto|
                machine.guest.capability(:add_iptables_rule, redirect_dns_rule(proto, dns_server, target.fetch(:host), target.fetch(:port)))
              end
            end
          end

          private

          def redirect_dns_rule(protocol, original_server, target_server, target_port)
            "OUTPUT -t nat -p #{protocol} -d #{original_server} --dport 53 -j DNAT --to-destination #{target_server}:#{target_port}"
          end

          def enable_route_localnet(machine)
            command = "sh -c 'echo 1 > /proc/sys/net/ipv4/conf/all/route_localnet'"
            machine.communicate.sudo(command) do |data, type|
              if %i[stderr stdout].include?(type)
                color = type == :stdout ? :green : :red
                machine.env.ui.info(data.chomp, color: color, prefix: false)
              end
            end
          end
        end
      end
    end
  end
end
