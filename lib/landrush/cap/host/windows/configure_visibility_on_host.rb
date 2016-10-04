# This file needs to be able to execute out of the Vagrant context. Do not require any non core or non relative files
require 'ipaddr'
require_relative '../../../util/retry'

module Landrush
  module Cap
    module Windows
      class ConfigureVisibilityOnHost
        # Windows registry path under which network interface configuration is stored
        INTERFACES = 'SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters\\Interfaces'.freeze

        class << self
          def configure_visibility_on_host(env, ip, tld)
            @env = env
            update_network_adapter(ip, tld) if ensure_prerequisites
          end

          # If this registry query succeeds we assume we have Admin rights
          # http://stackoverflow.com/questions/8268154/run-ruby-script-in-elevated-mode/27954953
          def admin_mode?
            (`reg query HKU\\S-1-5-19 2>&1` =~ /ERROR/).nil?
          end

          private

          # Checks that all required tools are on the PATH and that the Wired AutoConfig service is started
          def ensure_prerequisites
            return false unless command_found('netsh')
            return false unless command_found('net')
            return false unless command_found('reg')

            unless wired_autoconfig_service_running?
              info('starting \'Wired AutoConfig\' service')
              if admin_mode?
                `net start dot3svc`
              else
                require 'win32ole'
                shell = WIN32OLE.new('Shell.Application')
                shell.ShellExecute('net', 'start dot3svc', nil, 'runas', 1)
              end
              service_has_started = Landrush::Util::Retry.retry(tries: 5, sleep: 1) do
                wired_autoconfig_service_running?
              end
              unless service_has_started
                info('Unable to start \'Wired AutoConfig\' service. Unable to configure DNS on host. Try manual configuration.')
                return false
              end
              info('\'Wired AutoConfig\' service has started.')
            end
            true
          end

          # Does the actual update of the network configuration
          def update_network_adapter(ip, tld)
            # Need to defer loading to ensure cross OS compatibility
            require 'win32/registry'
            if admin_mode?
              network_name = get_network_name(ip)
              if network_name.nil?
                info("unable to determine network interface for #{ip}. DNS on host cannot be configured. Try manual configuration.")
                return
              else
                info("adding Landrush'es DNS server to network '#{network_name}' using DNS IP '#{ip}'' and search domain '#{tld}'")
              end
              network_guid = get_guid(network_name)
              if network_guid.nil?
                info("unable to determine network GUID for #{ip}. DNS on host cannot be configured. Try manual configuration.")
                return
              end
              interface_path = INTERFACES + "\\{#{network_guid}}"
              Win32::Registry::HKEY_LOCAL_MACHINE.open(interface_path, Win32::Registry::KEY_ALL_ACCESS) do |reg|
                reg['NameServer'] = '127.0.0.1'
                reg['Domain'] = tld
              end
            else
              run_with_admin_privileges(__FILE__.to_s, ip, tld)
            end
          end

          # Given a network name (as displayed on 'Control Panel\Network and Internet\Network Connections'),
          # determines the GUID of this network interface using 'netsh'.
          #
          # To make this work the "Wired Autoconfig" service must be started (go figure).
          #
          # Output of netsh command which is being processed:
          #
          # There are 4 interfaces on the system:
          #
          # Name             : Ethernet
          # Description      : Intel(R) Ethernet Connection (3) I218-LM
          # GUID             : fd9270f6-aff6-4f24-bc4a-1f90c032d5c3
          # Physical Address : 50-7B-9D-AB-25-1D
          # \n\n
          # ...
          def get_guid(network_name)
            cmd_out = `netsh lan show interfaces`
            interface_details = cmd_out.split(/\n\n/).select { |settings| settings.match(/#{Regexp.quote(network_name)}/m) }
            return nil if interface_details.empty?
            interface_details[0].split(/\n/)[2].match(/.*:(.*)/).captures[0].strip
          end

          # Given an IP determines the network name, if any. Uses netsh which generates output like this:
          #
          # ...
          # \n\n
          # Configuration for interface "Ethernet 2"
          #    DHCP enabled:                         Yes
          #    IP Address:                           10.10.10.1
          #    Subnet Prefix:                        10.10.10.0/24 (mask 255.255.255.0)
          #    InterfaceMetric:                      10
          #    DNS servers configured through DHCP:  None
          #    Register with which suffix:           Primary only
          #    WINS servers configured through DHCP: None
          # \n\n
          # ...
          def get_network_name(ip)
            cmd_out = `netsh interface ip show config`
            network_details = cmd_out.split(/\n\n/).select do |settings|
              begin
                lines = settings.split(/\n/).reject(&:empty?)
                subnet = lines[3]
                next false unless subnet =~ /Subnet Prefix/

                mask = IPAddr.new(subnet.match(%r{.* (\d{1,3}\.\d{1,3}\.\d{1,3}.\d{1,3}/\d{1,3}).*}).captures[0])
                address = IPAddr.new(ip)

                mask.include?(address)
              rescue
                false
              end
            end
            return nil if network_details[0].nil?
            network_details[0].split(/\n/)[0].match(/Configuration for interface "(.*)"/).captures[0].strip
          end

          # Makes sure that we have admin privileges and if nor starts a new shell with the required
          # privileges
          def run_with_admin_privileges(file, *args)
            require 'win32ole'
            shell = WIN32OLE.new('Shell.Application')
            shell.ShellExecute('ruby', "#{file} #{args.join(' ')}", nil, 'runas', 1)
          end

          def info(msg)
            @env.ui.info("[landrush] #{msg}") unless @env.nil?
          end

          def wired_autoconfig_service_running?
            cmd_out = `net start`
            cmd_out =~ /Wired AutoConfig/m
          end

          def command_found(cmd)
            if which(cmd).nil?
              info("Cannot find '#{cmd}' on the PATH. Unable to configure DNS. Try manual configuration.")
              false
            else
              true
            end
          end

          # Cross-platform way of finding an executable in the $PATH.
          #
          #   which('ruby') #=> /usr/bin/ruby
          def which(cmd)
            exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
            ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
              exts.each do |ext|
                exe = File.join(path, "#{cmd}#{ext}")
                return exe if File.executable?(exe) && !File.directory?(exe)
              end
            end
            nil
          end
        end
      end
    end
  end
end

# Only run the following code when this file is the main file being run
# instead of having been required or loaded by another file
if __FILE__ == $PROGRAM_NAME
  Landrush::Cap::Windows::ConfigureVisibilityOnHost.configure_visibility_on_host(nil, ARGV[0], ARGV[1])
end
