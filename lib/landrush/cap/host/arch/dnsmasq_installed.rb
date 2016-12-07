module Landrush
  module Cap
    module Arch
      module DnsmasqInstalled
        def self.dnsmasq_installed(_env, *_args)
          system('pacman -Q dnsmasq > /dev/null 2>&1')
        end
      end
    end
  end
end
