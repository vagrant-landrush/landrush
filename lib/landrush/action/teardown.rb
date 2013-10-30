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
        else
          info "there are #{DependentVMs.count} VMs left, leaving DNS server and static entries"
          info DependentVMs.list.map { |dvm| " - #{dvm}" }.join("\n")
        end
      end

      def teardown_machine_dns
        info "removing machine entry: #{machine_hostname}"
        Store.hosts.delete(machine_hostname)
      end

      def teardown_static_dns
        global_config.landrush.hosts.each do |static_hostname, _|
          info "removing static entry: #{static_hostname}"
          Store.hosts.delete static_hostname
        end
      end

      def teardown_server
        Server.stop
      end
    end
  end
end
