module Landrush
  module Action
    class Teardown
      def initialize(app, env)
        @app = app
      end

      def call(env)
        @env = env
        teardown if env[:global_config].landrush.enabled?
        @app.call(@env)
      end

      def teardown
        teardown_machine_dns
        DependentVMs.remove(@env[:machine])

        if DependentVMs.none?
          teardown_static_dns
          teardown_server
        else
          info "there are #{DependentVMs.count} VMs left, leaving DNS server and static entries"
          info DependentVMs.list.map { |dvm| " - #{dvm}" }.join("\n")
        end
      end

      def teardown_machine_dns
        hostname = Util.hostname(@env[:machine])
        info "removing machine entry: #{hostname}"
        Store.hosts.delete(hostname)
      end

      def teardown_static_dns
        @env[:global_config].landrush.hosts.each do |hostname, _|
          info "removing static entry: #{hostname}"
          Store.hosts.delete hostname
        end
      end

      def teardown_server
        Server.stop
      end

      def info(msg)
        @env[:ui].info "[landrush] #{msg}"
      end
    end
  end
end
