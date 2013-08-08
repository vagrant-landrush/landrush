module Landrush
  module Action
    class RedirectDns
      SUPPORTED_PROVIDERS = {
        'VagrantPlugins::ProviderVirtualBox::Provider' => :virtualbox,
        'HashiCorp::VagrantVMwarefusion::Provider' => :vmware_fusion,
      }

      def initialize(app, env)
        @app = app
      end

      def call(env)
        if env[:global_config].landrush.enabled?
          @machine = env[:machine]

          @machine.ui.info "setting up machine's DNS to point to our server"
          @machine.guest.capability(:redirect_dns, host: _target_host, port: 10053)

          @machine.config.vm.networks.each do |type, options|
            @machine.ui.info "network: #{type.inspect}, #{options.inspect}"
          end
        end

        @app.call(env)
      end

      def _target_host
        case _provider
        when :virtualbox then
          '10.0.2.2'
        when :vmware_fusion then
          _gateway_for_ip(@machine.guest.capability(:configured_dns_server))
        end
      end

      def _provider
        SUPPORTED_PROVIDERS.fetch(@machine.provider.class.name) { |key|
          raise "I don't support the #{key} provider yet!"
        }
      end

      # Poor man's gateway; strip the last octet and jam a 1 on there.
      def _gateway_for_ip(ip)
        ip.split('.').tap(&:pop).push(1).join('.')
      end
    end
  end
end

