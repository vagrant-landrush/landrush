module VagrantRubydns
  module Action
    class Setup
      def initialize(app, env)
        @app = app
      end

      def call(env)
        Config.set(Util.hostname(env), Util.ip_address(env))

        @app.call(env)
      end
    end
  end
end
