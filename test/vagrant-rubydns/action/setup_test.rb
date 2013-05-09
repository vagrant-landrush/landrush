require 'test_helper'
require 'vagrant-rubydns/action/setup'

module VagrantRubydns
  module Action
    describe Setup do
      it "calls the next app in the chain" do
        env = fake_environment(called: false)
        app = lambda { |e| e[:called] = true }
        setup = Setup.new(app, nil)

        setup.call(env)

        env[:called].must_equal true
      end

      it "stores the machine's hostname => ip address" do
        app = Proc.new {}
        setup = Setup.new(app, nil)
        env = fake_environment_with_machine('somehost.vagrant.dev', '1.2.3.4')

        setup.call(env)

        Store.hosts.get('somehost.vagrant.dev').must_equal '1.2.3.4'
      end

      it "records the booting host as a dependent VM" do
        app = Proc.new {}
        setup = Setup.new(app, nil)
        env = fake_environment_with_machine('somehost.vagrant.dev', '1.2.3.4')

        setup.call(env)

        DependentVMs.list.must_equal %w[somehost.vagrant.dev]
      end

      it "starts the rubydns server if it's not already started" do
        app = Proc.new {}
        setup = Setup.new(app, nil)
        env = fake_environment_with_machine('somehost.vagrant.dev', '1.2.3.4')

        setup.call(env)

        Server.running?.must_equal true
      end

      it "does not attempt to start the server if it's already up" do
        app = Proc.new {}
        setup = Setup.new(app, nil)
        env = fake_environment_with_machine('somehost.vagrant.dev', '1.2.3.4')

        Server.start
        original_pid = Server.pid

        setup.call(env)

        Server.running?.must_equal true
        Server.pid.must_equal original_pid
      end

      it "does nothing if it is not enabled via config" do
        app = Proc.new {}
        setup = Setup.new(app, nil)
        env = fake_environment_with_machine('somehost.vagrant.dev', '1.2.3.4')

        env[:global_config].rubydns.disable
        setup.call(env)

        Store.hosts.get('somehost.vagrant.dev').must_equal nil
      end
    end
  end
end
