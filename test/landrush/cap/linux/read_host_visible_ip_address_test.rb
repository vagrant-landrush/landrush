require 'test_helper'

module Landrush
  module Cap
    module Linux

      describe ReadHostVisibleIpAddress do
        describe 'read_host_visible_ip_address' do
          let (:machine) { fake_machine }
          it 'should read the last address' do
            machine.communicate.stub_command(Landrush::Cap::Linux::ReadHostVisibleIpAddress.command, "1.2.3.4 5.6.7.8\n")
            machine.guest.capability(:read_host_visible_ip_address).must_equal '5.6.7.8'
          end
        end
      end

    end
  end
end

