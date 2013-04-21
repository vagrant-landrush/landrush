$:.push(File.expand_path('../../lib', __FILE__))

require 'bundler/setup'
require 'minitest/spec'

require 'support/fake_ui'

require 'vagrant-rubydns'

# must be called before minitest/autorun to ensure proper at_exit ordering
MiniTest::Unit.after_tests { VagrantRubydns::Store.clear! }

require 'minitest/autorun'

def fake_environment(extras={})
  env = Vagrant::Environment.new
  { ui: FakeUI, global_config: env.config_global }.merge(extras)
end

def fake_environment_with_machine(hostname, ip)
  provider_cls = Class.new do
    def initialize(machine)
    end
  end 

  env = Vagrant::Environment.new

  machine = Vagrant::Machine.new(
    'fake_machine',
    'fake_provider',
    provider_cls,
    'provider_config',
    env.config_global,
    Pathname('data_dir'),
    'box',
    env
  )

  machine.config.rubydns.enable

  machine.config.vm.hostname = hostname
  machine.config.vm.network :private_network, ip: ip

  { machine: machine, ui: FakeUI, global_config: env.config_global }
end
