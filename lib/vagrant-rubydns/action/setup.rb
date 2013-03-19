module VagrantRubydns
  module Action
    class Setup
      def initialize(app, env)
        @app = app
      end

      def call(env)
        @env = env

        configfile = ".vagrant_dns.json"

        config = JSON.parse(File.read(configfile))

        config[hostname] = ip_address

        File.open(configfile, "w") do |f|
          f.write(JSON.pretty_generate(config))
        end

        @app.call(env)
      end

      def hostname
        @env[:machine].config.vm.hostname
      end

      def ip_address
        @env[:machine].config.vm.networks.each do |type, options|
          if type == :private_network && options[:ip].is_a?(String)
            return options[:ip]
          end
        end

        nil
      end

    end
  end
end
