require 'test_helper'

module Landrush
  describe Server do
    def query(host)
      output = `dig -p #{Server.port} @127.0.0.1 #{host}`
      answer_line = output.split("\n").grep(/^#{Regexp.escape(host)}/).first
      answer_line.split.last
    end

    def query_ptr(host)
      output = `dig ptr -p #{Server.port} @127.0.0.1 #{host}`
      answer_line = output.split("\n").grep(/^#{Regexp.escape(host)}/).first
      answer_line.split.last
    end

    describe 'start/stop' do
      it 'starts and stops a daemon' do
        Server.start
        Server.running?.must_equal true

        Server.stop
        Server.running?.must_equal false
      end

      # FIXME: This test requires network access.
      #        Which is not airplane hacking friendly. >:p
      it 'can be queried for upstream entries' do
        skip("needs network, and I am on an airplane without wifi")
        Server.start

        query("phinze.com").must_match(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/)
      end

      it 'responds properly to configured machine entries' do
        Server.start

        fake_host = 'boogers.vagrant.dev'
        fake_ip = '99.98.97.96'

        Store.hosts.set(fake_host, fake_ip)

        query(fake_host).must_equal fake_ip
        query_ptr(fake_host).must_equal fake_ip+'.'

      end

      it 'also resolves wildcard subdomains to a given machine' do
        Server.start

        fake_host = 'boogers.vagrant.dev'
        fake_ip = '99.98.97.96'

        Store.hosts.set(fake_host, fake_ip)

        query("green.#{fake_host}").must_match(fake_ip)
        query("blue.#{fake_host}").must_match(fake_ip)
      end
    end
  end
end
