module Landrush
  module Cap
    module Debian
      class DnsmasqInstalled
        def self.dnsmasq_installed(_env)
          system('dpkg -s dnsmasq > /dev/null 2>&1')
        end
      end
    end
  end
end
