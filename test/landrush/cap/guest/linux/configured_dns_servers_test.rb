require_relative '../../../../test_helper'

describe Landrush::Cap::Linux::ConfiguredDnsServers do
  let(:machine) { fake_machine }

  before do
    Landrush::Cap::Linux::ConfiguredDnsServers.instance_variable_set('@dns_servers', nil)
  end

  describe 'configured_dns_servers' do
    it 'parses out a single resolv.conf dns server' do
      machine.communicate.stubs(:sudo).yields(:stdout, 'nameserver 12.23.34.45')

      dns_servers = Landrush::Cap::Linux::ConfiguredDnsServers.configured_dns_servers(machine)

      dns_servers.must_equal(['12.23.34.45'])
    end

    it 'parses out multiple the resolv.conf dns servers' do
      machine.communicate.stubs(:sudo).yields(:stdout, [
        'nameserver 12.23.34.45',
        'nameserver 45.34.23.12'
      ].join("\n"))

      dns_servers = Landrush::Cap::Linux::ConfiguredDnsServers.configured_dns_servers(machine)

      dns_servers.must_equal([
                               '12.23.34.45',
                               '45.34.23.12'
                             ])
    end
  end
end
