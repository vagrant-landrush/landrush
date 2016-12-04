module Landrush
  module Cap
    module Arch
      module InstallDnsmasq
        class << self
          def install_dnsmasq(_env)
            system('pacman -Sy --noconfirm > /dev/null 2>&1')
            system('sudo pacman -S --noconfirm dnsmasq > /dev/null 2>&1')

            system('sudo sed -i "/^#conf-dir=\/etc\/dnsmasq.d$/s/^#//g" /etc/dnsmasq.conf')
          end
        end
      end
    end
  end
end
