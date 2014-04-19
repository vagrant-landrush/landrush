require 'test_helper'

module Landrush
  describe Server do
    def query(host, type = 'a')
      output = `dig -p #{Server.port} @127.0.0.1 #{host} #{type}`
      answer_line = output.split("\n").grep(/^#{Regexp.escape(host)}/).first
      answer_line || fail("No record for host #{host}")
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

      focus
      it 'responds properly to configured machine entries' do
        Server.start

        fake_host = 'boogers.vagrant.test'

        Store.hosts.set(fake_host, '99.98.97.96')

        query(fake_host).must_equal "boogers.vagrant.test.\t0\tIN\tA\t99.98.97.96"
        query(fake_host, 'ptr').must_equal "boogers.vagrant.test.\t0\tIN\tA\t99.98.97.96"
      end

      it 'responds properly to configured SRV entries' do
        Server.start

        fake_host = '_sip._udp.boogers.vagrant.test'

        Store.hosts.set(fake_host, [1, 0, 5060, 'boogers.vagrant.test'], 'srv')

        query(fake_host, 'srv').must_equal "_sip._udp.boogers.vagrant.test. 0 IN\tSRV\t1 0 5060 boogers.vagrant.test."
      end

      it 'responds properly to configured cname entries' do
        Server.start

        fake_host = 'boogers.vagrant.test'
        fake_cname = 'snot.vagrant.test'
        fake_ip = '99.98.97.96'

        Store.hosts.set(fake_host, fake_ip)
        Store.hosts.set(fake_cname, fake_host)

        query(fake_cname).must_equal fake_host+'.'
      end

      it 'also resolves wildcard subdomains to a given machine' do
        Server.start

        fake_host = 'boogers.vagrant.test'
        fake_ip = '99.98.97.96'

        Store.hosts.set(fake_host, fake_ip)

        query("green.#{fake_host}").must_match(fake_ip)
        query("blue.#{fake_host}").must_match(fake_ip)
      end
    end
  end
end
