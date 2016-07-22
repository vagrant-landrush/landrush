module Landrush
  module Cap
    module Redhat
      module DnsmasqInstalled
        def self.dnsmasq_installed(_env, *_args)
          system('rpm -qa | grep dnsmasq > /dev/null 2>&1')
        end
      end
    end
  end
end
