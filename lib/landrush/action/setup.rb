module Landrush
  module Action
    class Setup
      def initialize(app, env)
        @app = app
      end

      def call(env)
        if env[:global_config].landrush.enabled?
          DependentVMs.add(env[:machine])
          start_server_if_necessary(env)
          setup_machine_dns(env)
          setup_static_dns(env)
        end
        @app.call(env)
      end

      def start_server_if_necessary(env)
        if Server.running?
          env[:ui].info "[landrush] dns server already running"
        else
          env[:ui].info "[landrush] starting dns server"
          Server.start
        end
      end

      def setup_machine_dns(env)
        hostname, ip_address = Util.host_and_ip(env[:machine])
        env[:ui].info "[landrush] adding machine entry: #{hostname} => #{ip_address}"
        Store.hosts.set(hostname, ip_address)
      end

      def setup_static_dns(env)
        env[:global_config].landrush.hosts.each do |hostname, ip_address|
          env[:ui].info "[landrush] adding static entry: #{hostname} => #{ip_address}"
          Store.hosts.set hostname, ip_address
        end
      end
    end
  end
end
