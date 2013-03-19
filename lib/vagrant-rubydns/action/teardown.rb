module VagrantRubydns
  module Action
    class Teardown
      def initialize(app, env)
        @app = app
      end

      def call(env)
        Config.delete(Util.hostname(env))

        @app.call(env)
      end
    end
  end
end
