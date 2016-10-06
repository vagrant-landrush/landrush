module Landrush
  module Action
    class RedirectDns
      include Common

      def call(env)
        app.call(env)

        # This is after the middleware stack returns, which, since we're right
        # before the Network action, should mean that all interfaces are good
        # to go.
        redirect_dns if enabled? && guest_redirect_dns?
      end

      def redirect_dns
        info "setting up machine's DNS to point to our server"
        machine.guest.capability(:redirect_dns, host: _target_host, port: Server.port)

        machine.config.vm.networks.each do |type, options|
          info "network: #{type.inspect}, #{options.inspect}"
        end
      end

      def _target_host
        case provider
        when :virtualbox then
          '10.0.2.2'
        when :vmware_fusion, :libvirt then
          _gateway_for_ip(machine.guest.capability(:configured_dns_servers).first)
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
