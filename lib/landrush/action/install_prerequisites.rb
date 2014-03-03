module Landrush
  module Action
    class InstallPrerequisites
      include Common

      def call(env)
        handle_action_stack(env) do
          install_prerequisites if enabled? and manage_guests?
        end
      end

      def install_prerequisites
        unless machine.guest.capability(:iptables_installed)
          info 'iptables not installed, installing it'
          machine.guest.capability(:install_iptables)
        end
      end
    end
  end
end


