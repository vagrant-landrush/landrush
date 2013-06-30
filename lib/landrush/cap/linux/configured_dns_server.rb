module Landrush
  module Cap
    module Linux
      module ConfiguredDnsServer
        def self.configured_dns_server(machine)
          return @dns_server if @dns_server
          machine.communicate.sudo('cat /etc/resolv.conf | grep ^nameserver') do |type, data|
            if type == :stdout
              @dns_server = data.scan(/\d+\.\d+\.\d+\.\d+/).first
            end
          end
          @dns_server
        end
      end
    end
  end
end
