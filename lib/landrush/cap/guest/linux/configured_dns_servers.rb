module Landrush
  module Cap
    module Linux
      module ConfiguredDnsServers
        def self.configured_dns_servers(machine)
          return @dns_servers if @dns_servers
          machine.communicate.sudo('cat /etc/resolv.conf | grep ^nameserver') do |type, data|
            if type == :stdout
              @dns_servers = Array(data.scan(/\d+\.\d+\.\d+\.\d+/))
            end
          end
          @dns_servers
        end
      end
    end
  end
end
