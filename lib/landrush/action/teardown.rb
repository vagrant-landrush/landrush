module Landrush
  module Action
    class Teardown
      include Common

      def call(env)
        handle_action_stack(env) do
          teardown if enabled?
        end
      end

      def teardown
        teardown_machine_dns
        DependentVMs.remove(machine_hostname)

        if DependentVMs.none?
          teardown_static_dns
          teardown_server
        end
      end

      def teardown_machine_dns
        if Store.hosts.has? machine_hostname
          info "removing machine entry: #{machine_hostname}"
          Store.hosts.delete(machine_hostname)
        end
      end

      def teardown_static_dns
        config.hosts.each do |static_hostname, dns_value|
          if Store.hosts.has? static_hostname
            info "removing static entry: #{static_hostname}"
            Store.hosts.delete static_hostname
          end
        end
      end

      def teardown_server
        Server.stop
      end
    end
  end
end
