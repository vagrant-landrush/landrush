require 'test_helper'
require 'vagrant-rubydns/action/teardown'

module VagrantRubydns
  module Action
    describe Teardown do
      it "calls the next app in the chain" do
        env = {called: false, ui: FakeUI}
        app = lambda { |e| e[:called] = true }

        teardown = Teardown.new(app, nil)
        teardown.call(env)

        env[:called].must_equal true
      end

      it "stores the machine's hostname => ip address in the config" do
        Config.set('somehost.vagrant.dev', '1.2.3.4')

        app = Proc.new {}
        teardown = Teardown.new(app, nil)

        env = fake_environment_with_machine('somehost.vagrant.dev', '1.2.3.4')
        teardown.call(env)

        Config.get('somehost.vagrant.dev').must_equal nil
      end
    end
  end
end

