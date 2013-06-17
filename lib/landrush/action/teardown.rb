module Landrush
  module Action
    class Teardown
      def initialize(app, env)
        @app = app
      end

      def call(env)
        if env[:global_config].landrush.enabled?
          teardown_static_dns(env)
          teardown_machine_dns(env)

          DependentVMs.remove(env[:machine])
          stop_server_if_necessary(env)
        end
        @app.call(env)
      end

      def stop_server_if_necessary(env)
        if Server.running?
          if DependentVMs.none?
            env[:ui].info "[landrush] no dependent vms left, stopping dns server"
            Server.stop
          else
            env[:ui].info "[landrush] there are dependent vms left, leaving dns server"
          end
        else
          env[:ui].info "[landrush] dns server already stopped"
        end
      end

      def teardown_machine_dns(env)
        hostname = Util.hostname(env[:machine])
        env[:ui].info "[landrush] removing machine entry: #{hostname}"
        Store.hosts.delete(hostname)
      end

      def teardown_static_dns(env)
        env[:global_config].landrush.hosts.each do |hostname, _|
          env[:ui].info "[landrush] removing static entry: #{hostname}"
          Store.hosts.delete hostname
        end
      end
    end
  end
end
