$:.push(File.expand_path('../../lib', __FILE__))

require 'bundler/setup'
require 'minitest/spec'

require 'landrush'

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
    {}, # provider_options
    env.config_global,
    Pathname('data_dir'),
    'box',
    env
  )

  machine.config.landrush.enable

  machine.config.vm.hostname = hostname
  machine.config.vm.network :private_network, ip: ip

  { machine: machine, ui: FakeUI, global_config: env.config_global }
end

class MiniTest::Spec
  alias_method :hush, :capture_io
end

# order is important on these
require 'support/clear_dependent_vms'

require 'support/fake_ui'
require 'support/test_server_daemon'
require 'support/fake_resolver_config'

# need to be last; don't want to delete dir out from servers before they clean up
require 'support/fake_working_dir'
