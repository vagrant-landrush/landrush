$:.push(File.expand_path('../../lib', __FILE__))

require 'bundler/setup'
require 'minitest/spec'

require 'vagrant-rubydns'

require 'ruby-debug'

# must be called before minitest/autorun to ensure proper at_exit ordering
MiniTest::Unit.after_tests { VagrantRubydns::Config.clear! }

require 'minitest/autorun'

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

  machine.config.vm.hostname = hostname
  machine.config.vm.network :private_network, ip: ip

  { machine: machine }
end
