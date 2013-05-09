require 'test_helper'

module VagrantRubydns
  describe Server do
    after {
      if Server.running?
        Server.stop
      end
    }
    describe 'start/stop' do
      it 'starts and stops a daemon' do
        hush { Server.start }

        Server.running?.must_equal true

        hush { Server.stop }

        Server.running?.must_equal false
      end
    end
  end
end
