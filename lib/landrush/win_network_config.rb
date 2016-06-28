require 'ipaddr'

# This class configures the network interface on Windows for use with the Landrush DNS server.
# It makes use of the netsh executable which is assumed to be available on the Windows host.
module Landrush
  class WinNetworkConfig
    # Windows registry path under which network interface configuration is stored
    INTERFACES = 'SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters\\Interfaces'.freeze

    def initialize(env={})
      @env = env
    end

    # Checks that all required tools are on the PATH and that the Wired AutoConfig service is started
    def check_prerequisites
      info('Checking prerequisites for configuring DNS on host')

      if self.class.which('netsh').nil?
        info('Cannot find \'netsh\' on the PATH. Unable to configure DNS on host. Try manual configuration.')
        return false
      end

      if self.class.which('net').nil?
        info('Cannot find \'net\' on the PATH. Unable to configure DNS on host. Try manual configuration.')
        return false
      end

      if `net start`.match(/Wired AutoConfig/m).nil?
        info('Starting \'Wired AutoConfig\' service')
        if self.class.admin_mode?
          `net start dot3svc`
        else
          require 'win32ole'
          shell = WIN32OLE.new('Shell.Application')
          shell.ShellExecute('net', 'start dot3svc', nil, 'runas', 1)
        end
        service_started = `net start`.match(/Wired AutoConfig/m).nil?
        unless service_started
          info('Unable to \'Wired AutoConfig\' service. Unable to configure DNS on host. Try manual configuration.')
          return false
        end
      end
      true
    end

    # Does the actual update of the network configuration
    def update_network_adapter(ip, name_server, domain)
      # Need to defer loading to ensure cross OS compatibility
      require 'win32/registry'
      ensure_admin_privileges(__FILE__.to_s, ip, name_server, domain)
      network_name = get_network_name(ip)
      info("Setting DNS server for network \'#{network_name}\' to #{ip} and search domain to \'#{domain}\'")
      network_guid = get_guid(network_name)
      interface_path = INTERFACES + "\\{#{network_guid}}"
      Win32::Registry::HKEY_LOCAL_MACHINE.open(interface_path, Win32::Registry::KEY_ALL_ACCESS) do |reg|
        reg['NameServer'] = name_server
        reg['Domain'] = domain
      end
    end

    # Cross-platform way of finding an executable in the $PATH.
    def self.which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end
      nil
    end

    # If this registry query succeeds we assume we have Admin rights
    # http://stackoverflow.com/questions/8268154/run-ruby-script-in-elevated-mode/27954953
    def self.admin_mode?
      (`reg query HKU\\S-1-5-19 2>&1` =~ /ERROR/).nil?
    end

    private

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
        lines = settings.split(/\n/).reject(&:empty?)
        subnet = lines[3]
        next false unless subnet =~ /Subnet Prefix/

        mask = IPAddr.new(subnet.match(%r{.* (\d{1,3}\.\d{1,3}\.\d{1,3}.\d{1,3}/\d{1,3}).*}).captures[0])
        address = IPAddr.new(ip)

        mask.include?(address)
      end
      return nil if network_details[0].nil?
      network_details[0].split(/\n/)[0].match(/Configuration for interface "(.*)"/).captures[0].strip
    end

    # Makes sure that we have admin privileges and if nor starts a new shell with the required
    # privileges
    def ensure_admin_privileges(file, *args)
      unless self.class.admin_mode?
        require 'win32ole'
        shell = WIN32OLE.new('Shell.Application')
        shell.ShellExecute('ruby', "#{file} #{args.join(' ')}", nil, 'runas', 1)
        # need to exit current execution, changes will occur in new environment
        exit
      end
    end

    def info(msg)
      if @env.nil?
        puts "[landrush] #{msg}"
      else
        @env[:ui].info("[landrush] #{msg}")
      end
    end
  end
end

# Only run the following code when this file is the main file being run
# instead of having been required or loaded by another file
if __FILE__ == $0
  config = Landrush::WinNetworkConfig.new nil
  config.update_network_adapter(ARGV[0], ARGV[1], ARGV[2])
end
