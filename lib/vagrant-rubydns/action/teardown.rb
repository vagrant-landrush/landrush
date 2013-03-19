module VagrantRubydns
  module Action
    class Teardown
      def initialize(app, env)
        @app = app
        puts "I AM RUBYDNS TEARDOWN init"
      end

      def call(env)
        @env = env

        configfile = ".vagrant_dns.json"

        config = JSON.parse(File.read(configfile))

        config.delete hostname

        File.open(configfile, "w") do |f|
          f.write(JSON.pretty_generate(config))
        end

        @app.call(env)
      end

      def hostname
        @env[:machine].config.vm.hostname
      end

    end
  end
end
