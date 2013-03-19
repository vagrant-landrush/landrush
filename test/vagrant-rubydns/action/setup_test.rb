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
        Store.clear!

        app = Proc.new {}
        setup = Setup.new(app, nil)

        env = fake_environment_with_machine('somehost.vagrant.dev', '1.2.3.4')
        setup.call(env)

        Store.get('somehost.vagrant.dev').must_equal '1.2.3.4'
      end
    end
  end
end
