require 'test_helper'
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
        env = fake_environment
        app = -> (e) { e[:called] = true }
        setup = Setup.new(app, nil)

        setup.call(env)

        env[:called].must_equal true
      end

      it "records the booting host as a dependent VM" do
        app = proc {}
        setup = Setup.new(app, nil)
        env = fake_environment

        setup.call(env)

        DependentVMs.list.must_equal %w[somehost.vagrant.test]
      end

      it "starts the landrush server if it's not already started" do
        app = proc {}
        setup = Setup.new(app, nil)
        env = fake_environment

        setup.call(env)

        Server.running?.must_equal true
      end

      it "does not attempt to start the server if it's already up" do
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
        app = proc {}
        setup = Setup.new(app, nil)
        env = fake_environment

        env[:machine].config.landrush.disable
        setup.call(env)

        DependentVMs.list.must_equal []
      end

      describe 'after boot' do
        it "stores the machine's hostname => ip address" do
          app = proc {}
          setup = Setup.new(app, nil)
          env = fake_environment

          setup.call(env)

          Store.hosts.get('somehost.vagrant.test').must_equal '1.2.3.4'
        end

        it "does nothing if it is not enabled via config" do
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
