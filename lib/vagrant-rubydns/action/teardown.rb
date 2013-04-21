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
        end
        @app.call(env)
      end

      def teardown_machine_dns(env)
        hostname = Util.hostname(env[:machine])
        env[:ui].info "[rubydns] removing machine entry: #{hostname}"
        Store.delete(hostname)
      end

      def teardown_static_dns(env)
        env[:global_config].rubydns.hosts.each do |hostname, _|
          env[:ui].info "[rubydns] removing static entry: #{hostname}"
          Store.delete hostname
        end
      end
    end
  end
end
