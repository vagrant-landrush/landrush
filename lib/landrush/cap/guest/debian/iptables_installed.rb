module Landrush
  module Cap
    module Debian
      module IptablesInstalled
        def self.iptables_installed(machine)
          machine.communicate.test('dpkg -s iptables')
        end
      end
    end
  end
end
