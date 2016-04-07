require 'test_helper'
require 'resolv'

module Landrush
  describe Server do
    def query(host)
      Resolv::DNS.open(:nameserver_port => [["127.0.0.1", Server.port]]) do |r|
        r.getaddress(host).to_s
      end
    end

    def wait_for_port
      sleep 1 until (TCPSocket.open('127.0.0.1', Server.port) rescue nil)
    end

    describe 'start/stop' do
      it 'starts and stops a daemon' do
        Server.start
        Server.running?.must_equal true

        Server.stop
        Server.running?.must_equal false
      end

      # FIXME: This test requires network access.
      #       Which is not airplane hacking friendly. >:p
      it 'can be queried for upstream entries' do
        # skip("needs network, and I am on an airplane without wifi")
        Store.config.set('upstream', [[:udp, '8.8.8.8', 53], [:tcp, '8.8.8.8', 53]])

        Server.start

        wait_for_port

        query("phinze.com").must_match(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/)
      end

      it 'responds properly to configured machine entries' do
        Server.start

        fake_host = 'boogers.vagrant.dev'
        fake_ip = '99.98.97.96'

        Store.hosts.set(fake_host, fake_ip)

        wait_for_port

        query(fake_host).must_equal fake_ip
      end

      it 'responds properly to configured cname entries' do
        Server.start

        fake_host = 'boogers.vagrant.dev'
        fake_cname = 'snot.vagrant.dev'
        fake_ip = '99.98.97.96'

        Store.hosts.set(fake_host, fake_ip)
        Store.hosts.set(fake_cname, fake_host)

        wait_for_port

        query(fake_cname).must_equal fake_ip
      end

      it 'also resolves wildcard subdomains to a given machine' do
        Server.start

        fake_host = 'boogers.vagrant.dev'
        fake_ip = '99.98.97.96'

        Store.hosts.set(fake_host, fake_ip)

        wait_for_port

        query("green.#{fake_host}").must_match(fake_ip)
        query("blue.#{fake_host}").must_match(fake_ip)
      end
    end
  end
end
