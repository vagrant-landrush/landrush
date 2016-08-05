module Landrush
  module Cap
    module Redhat
      module RestartDnsmasq
        class << self
          SED_COMMAND = <<-EOF.gsub(/^ +/, '')
          sudo sed -i.orig '1 i\
          # Added by landrush, a vagrant plugin \\
          nameserver 127.0.0.1 \\
          ' /etc/resolv.conf
          EOF

          def restart_dnsmasq(_env)
            # TODO: At some stage we might want to make create_dnsmasq_config host specific and add the resolv.conf
            # changes there which seems more natural
            system(SED_COMMAND) unless system("cat /etc/resolv.conf | grep 'nameserver 127.0.0.1' > /dev/null 2>&1")
            system('sudo systemctl restart dnsmasq')
          end
        end
      end
    end
  end
end
