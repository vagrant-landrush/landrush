module Landrush
  module Cap
    module Debian
      class RestartDnsmasq
        def self.restart_dnsmasq(_env)
          system('sudo service dnsmasq restart > /dev/null 2>&1')
        end
      end
    end
  end
end
