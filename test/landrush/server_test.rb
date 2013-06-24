require 'test_helper'

module Landrush
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

      it 'can be queried for upstream entries' do
        hush { Server.start }

        output = `dig -p #{Server.port} @127.0.0.1 phinze.com`

        answer_line = output.split("\n").grep(/^phinze\.com\./).first

        answer_line.wont_equal nil

        ip_address = answer_line.split.last

        ip_address.must_match(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/)
      end
    end
  end
end
