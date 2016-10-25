module Landrush
  module Cap
    module Suse
      module InstallIptables
        def self.install_iptables(machine)
          machine.communicate.tap do |c|
            c.sudo('zypper -q clean')
            c.sudo('zypper -n -q install iptables')
          end
        end
      end
    end
  end
end
