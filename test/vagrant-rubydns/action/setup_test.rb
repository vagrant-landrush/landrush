require 'test_helper'
require 'vagrant-rubydns/action/setup'

module VagrantRubydns
  module Action
    describe Setup do
      it "calls the next app in the chain" do
        env = {called: false}
        app = lambda { |e| e[:called] = true }

        setup = Setup.new(app, nil)
        setup.call(env)

        env[:called].must_equal true
      end

      it "stores the machine's hostname => ip address in the config" do
        Config.clear!

        app = Proc.new {}
        env = fake_environment_with_machine('somehost.vagrant.dev', '1.2.3.4')
        setup = Setup.new(app, nil)

        setup.call(env)

        Config.get('somehost.vagrant.dev').must_equal '1.2.3.4'
      end
    end
  end
end

