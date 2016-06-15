module Landrush
  module Cap
    module Linux
      module ConfiguredDnsServers
        def self.configured_dns_servers(machine)
          return @dns_servers if @dns_servers
          machine.communicate.sudo('sed -ne \'s/^nameserver \([0-9.]*\)$/\1/p\' /etc/resolv.conf') do |type, data|
            if type == :stdout
              @dns_servers = Array(data.scan(/\d+\.\d+\.\d+\.\d+/)) unless data.to_s.empty?
            end
          end
          @dns_servers
        end
      end
    end
  end
end
