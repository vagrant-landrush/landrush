module VagrantRubydns
  module Action
    class RedirectDns
      def initialize(app, env)
        @app = app
      end

      def call(env)
        @machine = env[:machine]

        @machine.ui.info "setting up machine's DNS to point to our server"

        redirect_dns('10.0.2.3', 53, '10.0.2.2', 10053)
      end

      def redirect_dns(original_server, original_port, target_server, target_port)
        %w[tcp udp].each do |protocol|
          rule = "OUTPUT -t nat -d #{original_server} -p #{protocol} --dport #{original_port} -j DNAT --to-destination #{target_server}:#{target_port}"
          command = %Q(iptables -C #{rule} 2> /dev/null || iptables -A #{rule})
          _run_command(command)
        end
      end

      def _run_command(command)
        @machine.communicate.sudo(command) do |data, type|
          if [:stderr, :stdout].include?(type)
            color = (type == :stdout) ? :green : :red
            @machine.env.ui.info(data.chomp, :color => color, :prefix => false)
          end
        end
      end
    end
  end
end

