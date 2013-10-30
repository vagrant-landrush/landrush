module Landrush
  module Action
    module Common
      SUPPORTED_PROVIDERS = {
        'VagrantPlugins::ProviderVirtualBox::Provider' => :virtualbox,
        'HashiCorp::VagrantVMwarefusion::Provider'     => :vmware_fusion,
        'Landrush::FakeProvider'                       => :fake_provider,
      }

      def self.included(base)
        base.send :attr_reader, :app, :env
      end

      def initialize(app, env)
        @app = app
      end

      def handle_action_stack(env)
        @env = env

        yield

        app.call(env)
      end

      def virtualbox?
        provider == :virtualbox
      end

      def vmware?
        provider == :vmware_fusion
      end

      def provider
        SUPPORTED_PROVIDERS.fetch(machine.provider.class.name) { |key|
          raise "The landrush plugin does not support the #{key} provider yet!"
        }
      end

      def global_config
        env[:global_config]
      end

      def machine
        env[:machine]
      end

      def machine_hostname
        machine.config.vm.hostname
      end

      def enabled?
        global_config.landrush.enabled?
      end

      def info(msg)
        env[:ui].info "[landrush] #{msg}"
      end
    end
  end
end
