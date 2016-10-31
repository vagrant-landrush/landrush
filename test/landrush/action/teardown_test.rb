require_relative '../../test_helper'
require 'landrush/action/common'
require 'landrush/action/teardown'

module Landrush
  module Action
    describe Teardown do
      it 'calls the next app in the chain' do
        env = fake_environment
        app = -> (e) { e[:called] = true }
        teardown = Teardown.new(app, env)

        teardown.call(env)

        env[:called].must_equal true
      end

      it "clears the machine's hostname => ip address" do
        app = proc {}
        env = fake_environment
        teardown = Teardown.new(app, env)

        Store.hosts.set('somehost.vagrant.test', '1.2.3.4')
        teardown.call(env)

        Store.hosts.get('somehost.vagrant.test').must_equal nil
      end

      it 'removes the machine as a dependent VM' do
        app = proc {}
        env = fake_environment
        teardown = Teardown.new(app, env)

        DependentVMs.add('somehost.vagrant.test')
        teardown.call(env)

        DependentVMs.list.must_equal []
      end

      it 'stops the landrush server when there are no dependent machines left' do
        app = proc {}
        env = fake_environment
        teardown = Teardown.new(app, env)

        Server.start
        teardown.call(env)

        Server.running?.must_equal false
      end

      it 'leaves the landrush server when other dependent vms exist' do
        app = proc {}
        env = fake_environment
        teardown = Teardown.new(app, env)

        DependentVMs.add('otherhost.vagrant.test')

        Server.working_dir = File.join(env[:home_path], 'data', 'landrush')
        Server.gems_dir = env[:gems_path].to_s + '/gems'
        Server.start
        teardown.call(env)

        Server.running?.must_equal true
      end

      it 'leaves static entries when other dependent vms exist' do
        app = proc {}
        env = fake_environment
        teardown = Teardown.new(app, env)

        DependentVMs.add('otherhost.vagrant.test')

        fake_static_entry(env, 'static.vagrant.test', '3.4.5.6')

        teardown.call(env)

        Store.hosts.get('static.vagrant.test').must_equal '3.4.5.6'
      end

      it "leaves the server alone if it's not running" do
        app = proc {}
        env = fake_environment
        teardown = Teardown.new(app, env)

        teardown.call(env)

        Server.running?.must_equal false
      end

      it 'does nothing when landrush is disabled' do
        # somewhat unrealistic since this entry shouldn't be there if it was
        # disabled in the first place, but oh well
        Store.hosts.set('somehost.vagrant.test', '1.2.3.4')

        app = proc {}
        env = fake_environment
        teardown = Teardown.new(app, env)
        env[:machine].config.landrush.disable

        teardown.call(env)

        Store.hosts.get('somehost.vagrant.test').must_equal '1.2.3.4'
      end
    end
  end
end
