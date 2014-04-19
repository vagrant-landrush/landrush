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
        info "removing machine entry: #{machine_hostname}"
        Store.hosts.delete(machine_hostname)
      end

      def teardown_static_dns
        config.hosts.each do |static_hostname, (_, type)|
          info "removing static entry: #{static_hostname} as #{type}"
          Store.hosts.delete static_hostname, type
        end
      end

      def teardown_server
        Server.stop
      end
    end
  end
end
