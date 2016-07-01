require_relative '../../test_helper'
require 'landrush/action/common'
require 'landrush/action/setup'

module Landrush
  module Action
    describe Setup do
      before do
        ResolverConfig.sudo = ''
      end

      after do
        ResolverConfig.sudo = 'sudo'
      end

      it "calls the next app in the chain" do
        skip('Not working on Windows, since it will also do the network config') if Vagrant::Util::Platform.windows?
        env = fake_environment
        app = -> (e) { e[:called] = true }
        setup = Setup.new(app, nil)

        setup.call(env)

        env[:called].must_equal true
      end

      it "records the booting host as a dependent VM" do
        skip('Not working on Windows, since it will also do the network config') if Vagrant::Util::Platform.windows?
        app = proc {}
        setup = Setup.new(app, nil)
        env = fake_environment

        setup.call(env)

        DependentVMs.list.must_equal %w[somehost.vagrant.test]
      end

      it "starts the landrush server if it's not already started" do
        skip('Not working on Windows, since it will also do the network config') if Vagrant::Util::Platform.windows?
        app = proc {}
        setup = Setup.new(app, nil)
        env = fake_environment

        setup.call(env)

        Server.running?.must_equal true
      end

      it "does not attempt to start the server if it's already up" do
        skip('Not working on Windows, since it will also do the network config') if Vagrant::Util::Platform.windows?
        app = proc {}
        setup = Setup.new(app, nil)
        env = fake_environment

        Server.start
        original_pid = Server.pid

        setup.call(env)

        Server.running?.must_equal true
        Server.pid.must_equal original_pid
      end

      it "does nothing if it is not enabled via config" do
        skip('Not working on Windows, since it will also do the network config') if Vagrant::Util::Platform.windows?
        app = proc {}
        setup = Setup.new(app, nil)
        env = fake_environment

        env[:machine].config.landrush.disable
        setup.call(env)

        DependentVMs.list.must_equal []
      end

      it "for single private network IP host visible IP can be retrieved w/o starting the VM" do
        skip('Not working on Windows, since it will also do the network config') if Vagrant::Util::Platform.windows?
        app = proc {}
        setup = Setup.new(app, nil)
        env = fake_environment
        env[:machine].config.vm.network :private_network, ip: '42.42.42.42'

        setup.call(env)
        Store.hosts.get('somehost.vagrant.test').must_equal '42.42.42.42'
      end

      it "for multiple private network IPs host visible IP cant be retrieved if host_ip_address is set" do
        skip('Not working on Windows, since it will also do the network config') if Vagrant::Util::Platform.windows?
        app = proc {}
        setup = Setup.new(app, nil)
        env = fake_environment

        env[:machine].config.vm.network :private_network, ip: '42.42.42.41'
        env[:machine].config.vm.network :private_network, ip: '42.42.42.42'
        env[:machine].config.landrush.host_ip_address = '42.42.42.42'
        setup.call(env)
        Store.hosts.get('somehost.vagrant.test').must_equal '42.42.42.42'
      end

      it "is possible to add cnames via the config.landrush.host configuration option" do
        skip('Not working on Windows, since it will also do the network config') if Vagrant::Util::Platform.windows?
        app = proc {}
        setup = Setup.new(app, nil)
        env = fake_environment

        env[:machine].config.landrush.host 'foo', 'bar'
        setup.call(env)

        Store.hosts.get('foo').must_equal 'bar'
      end

      describe 'after boot' do
        it "stores the machine's hostname => ip address" do
          skip('Not working on Windows, since it will also do the network config') if Vagrant::Util::Platform.windows?
          app = proc {}
          setup = Setup.new(app, nil)
          env = fake_environment

          setup.call(env)

          Store.hosts.get('somehost.vagrant.test').must_equal '1.2.3.4'
        end

        it "does nothing if it is not enabled via config" do
          skip('Not working on Windows, since it will also do the network config') if Vagrant::Util::Platform.windows?
          app = proc {}
          setup = Setup.new(app, nil)
          env = fake_environment(enabled: false)

          setup.call(env)

          Store.hosts.get('somehost.vagrant.test').must_equal nil
        end
      end
    end
  end
end
