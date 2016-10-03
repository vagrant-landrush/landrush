require_relative '../../../../test_helper'

module Landrush
  module Cap
    module All
      describe ReadHostVisibleIpAddress do
        let(:machine) { fake_machine }
        let(:addresses) { fake_addresses }

        def call_cap(machine)
          Landrush::Cap::All::ReadHostVisibleIpAddress.read_host_visible_ip_address(machine)
        end

        before do
          # TODO: Is there a way to only unstub it for read_host_visible_ip_address?
          machine.guest.unstub(:capability)
          machine.guest.stubs(:capability).with(:landrush_ip_installed).returns(true)
          machine.guest.stubs(:capability).with(:landrush_ip_get).returns(fake_addresses)
        end

        describe 'read_host_visible_ip_address' do
          # First, test with an empty response (no addresses)
          it 'should throw an error when there are no addresses' do
            machine.guest.stubs(:capability).with(:landrush_ip_get).returns([])

            lambda do
              call_cap(machine)
            end.must_raise(RuntimeError, 'No addresses found')
          end

          # Step 1: nothing excluded, nothing explicitly selected
          it 'should return the last address' do
            machine.config.landrush.host_interface          = nil
            machine.config.landrush.host_interface_excludes = []

            expected = addresses.last['ipv4']

            call_cap(machine).must_equal expected
          end

          # Test exclusion mechanics; it should select the las
          it 'should ignore interfaces that are excluded and select the last not excluded interface' do
            machine.config.landrush.host_interface          = nil
            machine.config.landrush.host_interface_excludes = [/exclude[0-9]+/]

            expected = addresses.detect { |a| a['name'] == 'include3' }
            expected = expected['ipv4']

            call_cap(machine).must_equal expected
          end

          # Explicitly select one; this supersedes the exclusion mechanic
          it 'should select the desired interface' do
            machine.config.landrush.host_interface          = 'include1'
            machine.config.landrush.host_interface_excludes = [/exclude[0-9]+/]

            expected = addresses.detect { |a| a['name'] == 'include1' }
            expected = expected['ipv4']

            call_cap(machine).must_equal expected
          end

          # Now make sure it returns the last not excluded interface when the desired interface does not exist
          it 'should return the last not excluded interface if the desired interface does not exist' do
            machine.config.landrush.host_interface          = 'dummy'
            machine.config.landrush.host_interface_excludes = [/exclude[0-9]+/]

            expected = addresses.detect { |a| a['name'] == 'include3' }
            expected = expected['ipv4']

            call_cap(machine).must_equal expected
          end

          # Now make sure it returns the last interface overall when nothing is excluded
          it 'should return the last interface if the desired interface does not exist' do
            machine.config.landrush.host_interface          = 'dummy'
            machine.config.landrush.host_interface_excludes = []

            expected = addresses.last['ipv4']

            call_cap(machine).must_equal expected
          end

          # Now, let's explicitly test the IPv4/IPv6 selection support, starting with the default (IPv4)
          it 'should return the last non-empty IPv4 address' do
            machine.config.landrush.host_interface          = nil
            machine.config.landrush.host_interface_excludes = [/exclude[0-9]+/, /include[0-9]+/]

            expected = addresses.detect { |a| a['name'] == 'ipv6empty2' }
            expected = expected['ipv4']

            call_cap(machine).must_equal expected
          end

          # Test IPv6 selection
          it 'should return the last non-empty IPv6 address' do
            machine.config.landrush.host_interface          = nil
            machine.config.landrush.host_interface_class    = :ipv6
            machine.config.landrush.host_interface_excludes = [/exclude[0-9]+/, /include[0-9]+/]

            expected = addresses.detect { |a| a['name'] == 'ipv4empty2' }
            expected = expected['ipv6']

            call_cap(machine).must_equal expected
          end

          # Test ANY selection
          it 'should return the last non-empty address of either class' do
            machine.config.landrush.host_interface          = nil
            machine.config.landrush.host_interface_class    = :any
            machine.config.landrush.host_interface_excludes = [/exclude[0-9]+/, /include[0-9]+/]

            expected = addresses.detect { |a| a['name'] == 'ipv4empty2' }
            expected = expected['ipv6']

            call_cap(machine).must_equal expected
          end
        end
      end
    end
  end
end
