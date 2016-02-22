require 'test_helper'

module Landrush
  module Cap
    module Linux
      describe ReadHostVisibleIpAddress do
        describe 'read_host_visible_ip_address' do
          let(:machine) { fake_machine }

          it 'should read the last address' do
            machine.communicate.stub_command(Landrush::Cap::Linux::ReadHostVisibleIpAddress.command, "1.2.3.4 5.6.7.8\n")
            machine.guest.capability(:read_host_visible_ip_address).must_equal '5.6.7.8'
          end

          it 'should ignore IPv6 addresses' do
            machine.communicate.stub_command(Landrush::Cap::Linux::ReadHostVisibleIpAddress.command, "1.2.3.4 5.6.7.8 fdb2:2c26:f4e4:0:21c:42ff:febc:ea4f\n")
            machine.guest.capability(:read_host_visible_ip_address).must_equal '5.6.7.8'
          end

          it 'should fail on invalid address' do
            machine.communicate.stub_command(Landrush::Cap::Linux::ReadHostVisibleIpAddress.command, "hello world\n")
            lambda do
              machine.guest.capability(:read_host_visible_ip_address)
            end.must_raise(IPAddr::InvalidAddressError)
          end

          it 'should fail without address' do
            machine.communicate.stub_command(Landrush::Cap::Linux::ReadHostVisibleIpAddress.command, "\n")
            lambda do
              machine.guest.capability(:read_host_visible_ip_address)
            end.must_raise(RuntimeError, 'Cannot detect IP address, command `hostname -I` returned ``')
          end
        end
      end
    end
  end
end
