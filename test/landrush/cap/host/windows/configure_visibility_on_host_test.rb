require_relative '../../../../test_helper'

TEST_IP = '10.42.42.42'.freeze

DOT_3_SVC_RUNNING = 'SERVICE_NAME: dot3svc
        TYPE               : 30  WIN32
        STATE              : 4  RUNNING
                                (STOPPABLE, NOT_PAUSABLE, ACCEPTS_SHUTDOWN)
        WIN32_EXIT_CODE    : 0  (0x0)
        SERVICE_EXIT_CODE  : 0  (0x0)
        CHECKPOINT         : 0x0
        WAIT_HINT          : 0x0
'.freeze

DOT_3_SVC_STOPPED = 'SERVICE_NAME: dot3svc
        TYPE               : 30  WIN32
        STATE              : 1  STOPPED
        WIN32_EXIT_CODE    : 0  (0x0)
        SERVICE_EXIT_CODE  : 0  (0x0)
        CHECKPOINT         : 0x0
        WAIT_HINT          : 0x0
'.freeze

NETSH_EXAMPLE = '
Configuration for interface "VirtualBox Host-Only Network #1"
    DHCP enabled:                         No
    IP Address:                           192.168.99.1
    Subnet Prefix:                        192.168.99.0/24 (mask 255.255.255.0)
    InterfaceMetric:                      25
    Statically Configured DNS Servers:    None
    Register with which suffix:           Primary only
    Statically Configured WINS Servers:   None

Configuration for interface "Ethernet"
    DHCP enabled:                         Yes
    IP Address:                           192.168.1.193
    Subnet Prefix:                        192.168.1.0/24 (mask 255.255.255.0)
    Default Gateway:                      192.168.1.1
    Gateway Metric:                       0
    InterfaceMetric:                      35
    DNS servers configured through DHCP:  192.168.1.1
    Register with which suffix:           Primary only
    WINS servers configured through DHCP: None

Configuration for interface "Loopback Pseudo-Interface 1"
    DHCP enabled:                         No
    IP Address:                           127.0.0.1
    Subnet Prefix:                        127.0.0.0/8 (mask 255.0.0.0)
    InterfaceMetric:                      75
    Statically Configured DNS Servers:    None
    Register with which suffix:           Primary only
    Statically Configured WINS Servers:   None
'.freeze

NETSH_EXAMPLE_SINGLE_INTERFACE = '
Configuration for interface "Ethernet"
    DHCP enabled:                         Yes
    IP Address:                           192.168.1.193
    Subnet Prefix:                        192.168.1.0/24 (mask 255.255.255.0)
    Default Gateway:                      192.168.1.1
    Gateway Metric:                       0
    InterfaceMetric:                      35
    DNS servers configured through DHCP:  192.168.1.1
    Register with which suffix:           Primary only
    WINS servers configured through DHCP: None
'.freeze

module Landrush
  module Cap
    module Windows
      describe ConfigureVisibilityOnHost do
        before do
          @vboxmanage_found = !Vagrant::Util::Which.which('VBoxManage').nil?
          @has_admin_privileges = Landrush::Cap::Windows::ConfigureVisibilityOnHost.admin_mode?
        end

        describe 'modify DNS settings of network adapter' do
          it 'sets 127.0.0.1 as DNS server on the interface' do
            skip('Only supported on Windows') unless Vagrant::Util::Platform.windows? && @vboxmanage_found && @has_admin_privileges

            # VBoxManage uses the network description for its commands whereas netsh uses the name
            # We need to get both
            begin
              old_network_state = network_state
              network_description = create_test_interface
              new_network_state = network_state
              network_name = get_network_name(old_network_state, new_network_state)

              get_dns_for_name(network_name).must_be_nil
              Landrush::Cap::Windows::ConfigureVisibilityOnHost.configure_visibility_on_host(fake_environment, TEST_IP, ['landrush.test'])
              get_dns_for_name(network_name).must_equal '127.0.0.1'
            rescue StandardError
              delete_test_interface network_description
            end
          end
        end

        describe '#wired_autoconfig_service_running?' do
          it 'service running' do
            Landrush::Cap::Windows::ConfigureVisibilityOnHost.expects(:wired_autoconfig_service_state).returns(DOT_3_SVC_RUNNING)
            assert ConfigureVisibilityOnHost.send(:wired_autoconfig_service_running?)
          end

          it 'service stopped' do
            Landrush::Cap::Windows::ConfigureVisibilityOnHost.expects(:wired_autoconfig_service_state).returns(DOT_3_SVC_STOPPED)
            refute ConfigureVisibilityOnHost.send(:wired_autoconfig_service_running?)
          end
        end

        describe '#get_network_name' do
          it 'returns network name for matching IP' do
            ConfigureVisibilityOnHost.expects(:`).with('netsh interface ip show config').returns(NETSH_EXAMPLE)
            expect(ConfigureVisibilityOnHost.get_network_name('192.168.1.193')).must_equal('Ethernet')
          end

          it 'returns nil for non matching IP' do
            ConfigureVisibilityOnHost.expects(:`).with('netsh interface ip show config').returns(NETSH_EXAMPLE)
            expect(ConfigureVisibilityOnHost.get_network_name('42.42.42.42')).must_be_nil
          end

          it 'returns nil for nil input' do
            ConfigureVisibilityOnHost.expects(:`).with('netsh interface ip show config').returns(NETSH_EXAMPLE)
            expect(ConfigureVisibilityOnHost.get_network_name(nil)).must_be_nil
          end

          it 'returns nil for empty input' do
            ConfigureVisibilityOnHost.expects(:`).with('netsh interface ip show config').returns(NETSH_EXAMPLE)
            expect(ConfigureVisibilityOnHost.get_network_name('')).must_be_nil
          end

          describe '#get_network_name' do
            it 'returns network name for single interface' do
              ConfigureVisibilityOnHost.expects(:`).with('netsh interface ip show config').returns(NETSH_EXAMPLE_SINGLE_INTERFACE)
              expect(ConfigureVisibilityOnHost.get_network_name('192.168.1.193')).must_equal('Ethernet')
            end
          end
        end

        def network_state
          `netsh interface ip show config`.split(/\n/).reject(&:empty?)
        end

        def get_network_name(old_network_state, new_network_state)
          new_network_state.reject! { |line| old_network_state.include? line }
          new_network_state[0].match(/.*"(.*)"$/).captures[0]
        end

        # Creates a test interface using VBoxMange and sets a known test IP
        def create_test_interface
          cmd_out = `VBoxManage hostonlyif create`
          network_description = cmd_out.match(/.*'(.*)'.*/).captures[0]
          `VBoxManage.exe hostonlyif ipconfig \"#{network_description}\" --ip #{TEST_IP}`
          sleep 3
          network_description
        end

        def delete_test_interface(name)
          `VBoxManage hostonlyif remove \"#{name}\"`
        end

        def get_dns_for_name(name)
          cmd_out = `netsh interface ip show config name=\"#{name}\"`
          dns = cmd_out.split(/\n/).select { |settings| settings.match(/Statically Configured DNS Servers/m) }
          # TODO: better error handling
          begin
            dns[0].match(/.* (\d{1,3}\.\d{1,3}\.\d{1,3}.\d{1,3}).*/).captures[0]
          rescue StandardError
            return nil
          end
        end
      end
    end
  end
end
