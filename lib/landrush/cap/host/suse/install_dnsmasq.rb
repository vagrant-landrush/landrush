module Landrush
  module Cap
    module Suse
      module InstallDnsmasq
        class << self
          def install_dnsmasq(_env)
            system('sudo zypper -q clean > /dev/null 2>&1')
            system('sudo zypper -n -q install dnsmasq > /dev/null 2>&1')
          end
        end
      end
    end
  end
end
