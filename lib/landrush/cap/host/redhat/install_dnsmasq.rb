module Landrush
  module Cap
    module Redhat
      module InstallDnsmasq
        class << self
          def install_dnsmasq(_env)
            system('sudo yum clean all > /dev/null 2>&1')
            system('sudo yum install -y -q dnsmasq > /dev/null 2>&1')
          end
        end
      end
    end
  end
end
