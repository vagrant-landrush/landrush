module VagrantRubydns
  module Action
    class Setup
      def initialize(app, env)
        @app = app
      end

      def call(env)
        hostname, ip_address = Util.host_and_ip(env[:machine])

        env[:ui].info "setting #{hostname} to #{ip_address} in in DNS"

        Store.set(hostname, ip_address)

        @app.call(env)
      end
    end
  end
end
