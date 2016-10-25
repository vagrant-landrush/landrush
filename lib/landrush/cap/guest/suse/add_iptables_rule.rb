module Landrush
  module Cap
    module Suse
      module AddIptablesRule
        def self.add_iptables_rule(machine, rule)
          _run(machine, %(/usr/sbin/iptables -C #{rule} 2> /dev/null || /usr/sbin/iptables -A #{rule}))
        end

        def self._run(machine, command)
          machine.communicate.sudo(command) do |data, type|
            if [:stderr, :stdout].include?(type)
              color = (type == :stdout) ? :green : :red
              machine.env.ui.info(data.chomp, color: color, prefix: false)
            end
          end
        end
      end
    end
  end
end
