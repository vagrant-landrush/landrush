module Landrush
  module Cap
    module Redhat
      module IptablesInstalled
        def self.iptables_installed(machine)
          machine.communicate.test('rpm -qa | grep iptables')
        end
      end
    end
  end
end
