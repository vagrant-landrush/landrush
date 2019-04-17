# This file needs to be able to execute out of the Vagrant context. Do not require any non core or non relative files
require 'ipaddr'
require 'English'
require_relative '../../../util/retry'

module Landrush
  module Cap
    module Windows
      class ConfigureVisibilityOnHost
        # Windows registry path under which network interface configuration is stored
        INTERFACES = 'SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters\\Interfaces'.freeze

        class << self
          def configure_visibility_on_host(env, ip, tlds)
            @env = env
            # tlds is an array. See also issue #177. For now we only support single TLD on windows, hence we select the
            # first element
            update_network_adapter(ip, tlds[0]) if ensure_prerequisites
          end

          # If this registry query succeeds we assume we have Admin rights
          # http://stackoverflow.com/questions/8268154/run-ruby-script-in-elevated-mode/27954953
          # https://stackoverflow.com/a/2400/1040571
          # "[...] $?, which is the same as $CHILD_STATUS,
          # accesses the status of the last system executed command if you use
          # the backticks, system() or %x{} [...]"
          def admin_mode?
            `reg query HKU\\S-1-5-19 2>&1`
            $CHILD_STATUS.exitstatus.zero?
          end

          # Given an IP determines the network adapter guid, if any.
          # We can't use netsh due to its output being locale dependant.
          # Using Windows registry we achieve the same result of netsh in
          # whatever language Windows is.
          def get_network_guid(address)
            address = IPAddr.new(address.to_s)

            interfaces do |interface_guid|
              interface = open_interface("#{INTERFACES}\\#{interface_guid}")
              if_ip, if_mask = interface_address(interface)

              next if if_ip.nil?

              if_net = IPAddr.new("#{if_ip}/#{if_mask}")
              return interface_guid if if_net.include?(address)
            end
          rescue StandardError
            nil
          end

          private

          # Fetch interfaces from registry
          # This is a separate method to make testing easier
          def interfaces
            Win32::Registry::HKEY_LOCAL_MACHINE.open(INTERFACES) do |interfaces|
              interfaces.each_key do |guid, _|
                yield guid
              end
            end
          end

          # Opens an interface key from registry
          # This is a separate method to make testing easier
          def open_interface(guid_path)
            Win32::Registry::HKEY_LOCAL_MACHINE.open(guid_path)
          end

          # Fetches IP/mask info from registry from a given registry entry
          # This is a separate method to make testing easier
          #
          # The registry may look like this:
          # {46666082-84ff-4888-8d75-31079e325934}:
          #         EnableDHCP => 1
          #         DhcpIPAddress => 172.29.5.24
          #         DhcpSubnetMask => 255.255.254.0
          # {61e509a1-cffa-4b7f-8e7f-5a6991deba2b}:
          #         EnableDHCP => 0
          #         IPAddress => ["192.168.56.1"]
          #         SubnetMask => ["255.255.255.0"]
          # {6c902ac7-4845-46d4-843e-2707e2270b0d}:
          #         EnableDHCP => 0
          #         IPAddress => ["0.0.0.0"]
          #         SubnetMask => ["0.0.0.0"]
          # {6d2f3579-bc95-4a18-bed5-fb8b87b8673b}:
          #         EnableDHCP => 0
          #
          # If a given interface does not have an address, win32/registry
          # will trow an Win32::Registry::Error (which inherits directly from StandardError).
          def interface_address(interface)
            dhcp_enabled = interface.read('EnableDHCP')[1]

            if dhcp_enabled
              if_ip = interface.read('DhcpIPAddress')[1]
              if_mask = interface.read('DhcpSubnetMask')[1]
            else
              if_ip = interface.read('IPAddress')[1]
              if_mask = interface.read('SubnetMask')[1]
            end

            if if_ip.is_a? Array
              if_ip = if_ip[0]
            end

            if if_mask.is_a? Array
              if_mask = if_mask[0]
            end

            if if_ip == '0.0.0.0'
              if_ip, if_mask = nil
            end

            [if_ip, if_mask]
          rescue StandardError
            [nil, nil]
          end

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
              address = IPAddr.new(ip)

              network_guid = get_network_guid(address)

              if network_guid.nil?
                info("unable to determine network GUID for #{ip}. DNS on host cannot be configured. Try manual configuration.")
                return
              end
              interface_path = INTERFACES + "\\#{network_guid}"
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

          def wired_autoconfig_service_state
            `sc query dot3svc`
          end

          def wired_autoconfig_service_running?
            cmd_out = wired_autoconfig_service_state
            cmd_out =~ /\s*STATE\s+:\s+4\s+RUNNING/m
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
if $PROGRAM_NAME == __FILE__
  Landrush::Cap::Windows::ConfigureVisibilityOnHost.configure_visibility_on_host(nil, ARGV[0], ARGV[1])
end
