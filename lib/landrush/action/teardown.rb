module Landrush
  module Action
    class Teardown
      include Common

      def call(env)
        # Make sure we use the right data directory for Landrush
        # Seems Vagrant only makes home_path available in this case, compared to custom commands where there is also data_dir
        Server.working_dir = File.join(env[:home_path], 'data', 'landrush')

        teardown if enabled?
        app.call(env)
      end

      def teardown
        teardown_machine_dns
        DependentVMs.remove(machine_hostname)

        return unless DependentVMs.none?
        teardown_static_dns
        teardown_server
      end

      def teardown_machine_dns
        return unless Store.hosts.has? machine_hostname
        info "removing machine entry: #{machine_hostname}"
        Store.hosts.delete(machine_hostname)
      end

      def teardown_static_dns
        config.hosts.each do |static_hostname|
          if Store.hosts.has? static_hostname
            info "removing static entry: #{static_hostname}"
            Store.hosts.delete static_hostname
          end
        end
      end

      def teardown_server
        Server.stop
      end
    end
  end
end
