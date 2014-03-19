module Landrush
  module Action
    class RedirectDns
      include Common

      def call(env)
        handle_action_stack(env) do
          redirect_dns if enabled?
        end
      end

      def redirect_dns
        info "setting up machine's DNS to point to our server"
        machine.guest.capability(:redirect_dns, host: _target_host, port: 10053)

        machine.config.vm.networks.each do |type, options|
          info "network: #{type.inspect}, #{options.inspect}"
        end
      end

      def _target_host
        case provider
        when :virtualbox then
          '10.0.2.2'
        when :vmware_fusion then
          _gateway_for_ip(machine.guest.capability(:configured_dns_server))
        when :parallels then
          machine.provider.capability(:host_address)
        end
      end

      # Poor man's gateway; strip the last octet and jam a 1 on there.
      def _gateway_for_ip(ip)
        ip.split('.').tap(&:pop).push(1).join('.')
      end
    end
  end
end

