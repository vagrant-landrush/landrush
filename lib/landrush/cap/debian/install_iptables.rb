module Landrush
  module Cap
    module Debian
      module InstallIptables
        def self.install_iptables(machine)
          machine.communicate.tap do |c|
            c.sudo('apt-get update')
            c.sudo('apt-get install -y iptables')
          end
        end
      end
    end
  end
end
