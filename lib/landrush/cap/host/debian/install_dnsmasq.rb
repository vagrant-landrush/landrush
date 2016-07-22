module Landrush
  module Cap
    module Debian
      class InstallDnsmasq
        def self.install_dnsmasq(_env)
          system('sudo apt-get update > /dev/null 2>&1')
          system('sudo apt-get install -y resolvconf dnsmasq > /dev/null 2>&1')
        end
      end
    end
  end
end
