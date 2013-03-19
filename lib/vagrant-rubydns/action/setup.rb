module VagrantRubydns
  module Action
    class Setup
      def initialize(app, env)
        @app = app
      end

      def call(env)
        setup_machine_dns(env)
        setup_static_dns(env)
        @app.call(env)
      end

      def setup_machine_dns(env)
        hostname, ip_address = Util.host_and_ip(env[:machine])
        env[:ui].info "[rubydns] adding machine entry: #{hostname} => #{ip_address}"
        Store.set(hostname, ip_address)
      end

      def setup_static_dns(env)
        env[:global_config].rubydns.hosts.each do |hostname, ip_address|
          env[:ui].info "[rubydns] adding static entry: #{hostname} => #{ip_address}"
          Store.set hostname, ip_address
        end
      end
    end
  end
end
