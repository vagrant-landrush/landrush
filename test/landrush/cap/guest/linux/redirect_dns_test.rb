require_relative '../../../../test_helper'

describe Landrush::Cap::Linux::RedirectDns do
  let(:machine) { fake_machine }

  describe 'redirect_dns' do
    it 'fetches the dns servers from the machine, and adds one iptables rule per server' do
      machine.guest.stubs(:capability).with(:configured_dns_servers).returns(%w(1.2.3.4 4.5.6.7))

      machine.guest.expects(:capability).with(:add_iptables_rule, 'OUTPUT -t nat -p tcp -d 1.2.3.4 --dport 53 -j DNAT --to-destination 2.3.4.5:4321').once
      machine.guest.expects(:capability).with(:add_iptables_rule, 'OUTPUT -t nat -p udp -d 1.2.3.4 --dport 53 -j DNAT --to-destination 2.3.4.5:4321').once
      machine.guest.expects(:capability).with(:add_iptables_rule, 'OUTPUT -t nat -p tcp -d 4.5.6.7 --dport 53 -j DNAT --to-destination 2.3.4.5:4321').once
      machine.guest.expects(:capability).with(:add_iptables_rule, 'OUTPUT -t nat -p udp -d 4.5.6.7 --dport 53 -j DNAT --to-destination 2.3.4.5:4321').once

      Landrush::Cap::Linux::RedirectDns.redirect_dns(
        machine,
        host: '2.3.4.5',
        port: '4321'
      )
    end
  end
end
