module Landrush
  module Action
    class InstallPrerequisites
      include Common

      def call(env)
        handle_action_stack(env) do
          install_prerequisites if enabled?
        end
      end

      def install_prerequisites
        if guest_redirect_dns? && !machine.guest.capability(:iptables_installed)
          info 'iptables not installed, installing it'
          machine.guest.capability(:install_iptables)
        end
      end
    end
  end
end
