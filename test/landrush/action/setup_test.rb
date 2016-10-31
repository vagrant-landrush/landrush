require_relative '../../test_helper'
require 'landrush/action/common'
require 'landrush/action/setup'

module Landrush
  module Action
    describe Setup do
      let(:env) { fake_environment }
      let(:app) { proc {} }

      before do
        env[:machine].config.landrush.host_redirect_dns = false
      end

      it 'calls the next app in the chain' do
        app = -> (e) { e[:called] = true }
        setup = Landrush::Action::Setup.new(app, env)

        setup.call(env)

        env[:called].must_equal true
      end

      it 'records the booting host as a dependent VM' do
        setup = Landrush::Action::Setup.new(app, env)

        setup.call(env)

        DependentVMs.list.must_equal %w(somehost.vagrant.test)
      end

      it "starts the landrush server if it's not already started" do
        setup = Landrush::Action::Setup.new(app, env)

        setup.call(env)

        Server.running?.must_equal true
      end

      it "does not attempt to start the server if it's already up" do
        setup = Landrush::Action::Setup.new(app, env)

        Server.working_dir = File.join(env[:home_path], 'data', 'landrush')
        Server.gems_dir = env[:gems_path].to_s + '/gems'
        Server.start
        original_pid = Server.pid

        setup.call(env)

        Server.running?.must_equal true
        Server.pid.must_equal original_pid
      end

      it 'does nothing if it is not enabled via config' do
        setup = Landrush::Action::Setup.new(app, env)

        env[:machine].config.landrush.disable
        setup.call(env)

        DependentVMs.list.must_equal []
      end

      it 'for multiple private network IPs host visible IP cant be retrieved if host_ip_address is set' do
        setup = Landrush::Action::Setup.new(app, env)

        env[:machine].config.vm.network :private_network, ip: '42.42.42.41'
        env[:machine].config.vm.network :private_network, ip: '42.42.42.42'
        env[:machine].config.landrush.host_ip_address = '42.42.42.42'
        setup.call(env)
        Store.hosts.get('somehost.vagrant.test').must_equal '42.42.42.42'
      end

      it 'is possible to add cnames via the config.landrush.host configuration option' do
        setup = Landrush::Action::Setup.new(app, env)

        env[:machine].config.landrush.host 'foo', 'bar'
        setup.call(env)

        Store.hosts.get('foo').must_equal 'bar'
      end

      describe 'after boot' do
        it "stores the machine's hostname => ip address" do
          setup = Landrush::Action::Setup.new(app, env)

          setup.call(env)

          Store.hosts.get('somehost.vagrant.test').must_equal '1.2.3.4'
        end

        it 'does nothing if it is not enabled via config' do
          env = fake_environment(enabled: false)
          setup = Landrush::Action::Setup.new(app, env)
          setup.call(env)

          Store.hosts.get('somehost.vagrant.test').must_equal nil
        end
      end
    end
  end
end
