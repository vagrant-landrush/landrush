module Landrush
  module Cap
    module Linux
      class ConfigureVisibilityOnHost
        class << self
          def configure_visibility_on_host(env, ip, tld)
            env[:host].capability(:install_dnsmasq) unless env[:host].capability(:dnsmasq_installed)
            env[:host].capability(:create_dnsmasq_config, ip, tld)
            env[:host].capability(:restart_dnsmasq)
          rescue Vagrant::Errors::CapabilityNotFound
            env[:ui].info('Unable to automatically configure your host. Check the documentation for manual ' \
              'instructions to configure the visibility on the host.')
          end
        end
      end
    end
  end
end
