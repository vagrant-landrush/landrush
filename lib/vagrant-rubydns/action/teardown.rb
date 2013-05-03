module VagrantRubydns
  module Action
    class Teardown
      def initialize(app, env)
        @app = app
      end

      def call(env)
        if env[:global_config].rubydns.enabled?
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
            env[:ui].info "[rubydns] no dependent vms left, stopping dns server"
            Server.stop
          else
            env[:ui].info "[rubydns] there are dependent vms left, leaving dns server"
          end
        else
          env[:ui].info "[rubydns] dns server already stopped"
        end
      end

      def teardown_machine_dns(env)
        hostname = Util.hostname(env[:machine])
        env[:ui].info "[rubydns] removing machine entry: #{hostname}"
        Store.hosts.delete(hostname)
      end

      def teardown_static_dns(env)
        env[:global_config].rubydns.hosts.each do |hostname, _|
          env[:ui].info "[rubydns] removing static entry: #{hostname}"
          Store.hosts.delete hostname
        end
      end
    end
  end
end
