module Landrush
  module Cap
    module Linux
      class ConfigureVisibilityOnHost
        class << self
          def configure_visibility_on_host(env, ip, tld)
            env.host.capability(:install_dnsmasq) unless env.host.capability(:dnsmasq_installed)
            env.host.capability(:create_dnsmasq_config, ip, tld)
            env.host.capability(:restart_dnsmasq)
          rescue Vagrant::Errors::CapabilityNotFound => e
            env.ui.info("Your host was detected as '#{e.extra_data[:host]}' for which the host capability " \
            "'#{e.extra_data[:cap]}' is not available.")
            env.ui.info('Check the documentation for the manual instructions to configure the visibility on the host.')
          end
        end
      end
    end
  end
end
