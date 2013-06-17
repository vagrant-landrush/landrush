require 'test_helper'
require 'landrush/action/teardown'

module Landrush
  module Action
    describe Teardown do
      it "calls the next app in the chain" do
        env = fake_environment(called: false)
        app = lambda { |e| e[:called] = true }
        teardown = Teardown.new(app, nil)

        teardown.call(env)

        env[:called].must_equal true
      end

      it "clears the machine's hostname => ip address" do
        app = Proc.new {}
        teardown = Teardown.new(app, nil)
        env = fake_environment_with_machine('somehost.vagrant.dev', '1.2.3.4')

        Store.hosts.set('somehost.vagrant.dev', '1.2.3.4')
        teardown.call(env)

        Store.hosts.get('somehost.vagrant.dev').must_equal nil
      end

      it "removes the machine as a dependent VM" do
        app = Proc.new {}
        teardown = Teardown.new(app, nil)
        env = fake_environment_with_machine('somehost.vagrant.dev', '1.2.3.4')

        DependentVMs.add(env[:machine])
        teardown.call(env)

        DependentVMs.list.must_equal []
      end

      it "stops the landrush server when there are no dependent machines left" do
        app = Proc.new {}
        teardown = Teardown.new(app, nil)
        env = fake_environment_with_machine('somehost.vagrant.dev', '1.2.3.4')

        Server.start
        teardown.call(env)

        Server.running?.must_equal false
      end

      it "leaves the landrush server when other dependent vms exist" do
        app = Proc.new {}
        teardown = Teardown.new(app, nil)
        env = fake_environment_with_machine('somehost.vagrant.dev', '1.2.3.4')

        other_env = fake_environment_with_machine('otherhost.vagrant.dev', '1.2.3.4')
        DependentVMs.add(other_env[:machine])

        Server.start
        teardown.call(env)

        Server.running?.must_equal true
      end

      it "leaves the server alone if it's not running" do
        app = Proc.new {}
        teardown = Teardown.new(app, nil)
        env = fake_environment_with_machine('somehost.vagrant.dev', '1.2.3.4')

        teardown.call(env)

        Server.running?.must_equal false
      end

      it "does nothing when landrush is disabled" do
        # somewhat unrealistic since this entry shouldn't be there if it was
        # disabled in the first place, but oh well
        Store.hosts.set('somehost.vagrant.dev', '1.2.3.4')

        app = Proc.new {}
        teardown = Teardown.new(app, nil)

        env = fake_environment_with_machine('somehost.vagrant.dev', '1.2.3.4')
        env[:global_config].landrush.disable

        teardown.call(env)

        Store.hosts.get('somehost.vagrant.dev').must_equal '1.2.3.4'
      end
    end
  end
end

