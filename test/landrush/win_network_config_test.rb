require_relative '../test_helper'

module Landrush
  TEST_IP = '10.42.42.42'.freeze

  describe WinNetworkConfig do
    before do
      @vboxmanage_found = !Vagrant::Util::Which.which('VBoxManage').nil?
      @has_admin_privileges = Landrush::WinNetworkConfig.admin_mode?
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

          config = Landrush::WinNetworkConfig.new(fake_environment)
          config.ensure_prerequisites.must_equal true
          config.update_network_adapter(TEST_IP, '127.0.0.1', 'landrush.test')

          get_dns_for_name(network_name).must_equal '127.0.0.1'
        rescue
          delete_test_interface network_description
        end
      end
    end

    def network_state
      `netsh interface ip show config`.split(/\n/).reject(&:empty?)
    end

    def get_network_name(old_network_state, new_network_state)
      new_network_state.reject! { |line| old_network_state.include? line }
      new_network_state[0].match(/.*\"(.*)\"$/).captures[0]
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
      rescue
        return nil
      end
    end
  end
end
