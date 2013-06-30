module Landrush
  module Action
    class InstallPrerequisites
      def initialize(app, env)
        @app = app
      end

      def call(env)
        @machine = env[:machine]
        @machine.ui.info('setting up prerequisites')

        install_prerequisites

        @app.call(env)
      end

      def install_prerequisites
        unless @machine.guest.capability(:iptables_installed)
          @machine.ui.info('iptables not installed, installing it')
          @machine.guest.capability(:install_iptables)
        end
      end
    end
  end
end


