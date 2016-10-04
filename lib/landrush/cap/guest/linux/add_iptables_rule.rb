module Landrush
  module Cap
    module Linux
      module AddIptablesRule
        def self.add_iptables_rule(machine, rule)
          _run(machine, %(iptables -C #{rule} 2> /dev/null || iptables -A #{rule}))
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
