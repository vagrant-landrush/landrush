module Landrush
  module Cap
    module Redhat
      module InstallIptables
        def self.install_iptables(machine)
          machine.communicate.tap do |c|
            c.sudo('yum clean all')
            c.sudo('yum install -y -q iptables')
          end
        end
      end
    end
  end
end
