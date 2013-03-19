module VagrantRubydns
  module Action
    class Teardown
      def initialize(app, env)
        @app = app
      end

      def call(env)
        hostname = Util.hostname(env[:machine])

        env[:ui].info "removing #{hostname} from DNS"

        Store.delete(hostname)

        @app.call(env)
      end
    end
  end
end
