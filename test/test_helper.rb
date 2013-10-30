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
  env = Vagrant::Environment.new
  machine = fake_machine(hostname, ip, env)
  { machine: machine, ui: FakeUI, global_config: env.config_global }
end

class RecordingCommunicator
  attr_reader :commands, :responses

  def initialize
    @commands = Hash.new([])
    @responses = Hash.new('')
  end

  def stub_command(command, response)
    responses[command] = response
  end

  def sudo(command)
    puts "SUDO: #{command}"
    commands[:sudo] << command
    responses[command]
  end

  def execute(command, &block)
    commands[:execute] << command
    responses[command].split("\n").each do |line|
      block.call(:stdout, "#{line}\n")
    end
  end

  def test(command)
    commands[:test] << command
    true
  end

  def ready?
    true
  end
end

class Landrush::FakeProvider
  def initialize(machine)
  end

  def ssh_info
  end
end

def fake_machine(hostname, ip, env = Vagrant::Environment.new)
  machine = Vagrant::Machine.new(
    'fake_machine',
    'fake_provider',
    Landrush::FakeProvider,
    'provider_config',
    {}, # provider_options
    env.config_global,
    Pathname('data_dir'),
    'box',
    env
  )

  machine.instance_variable_set("@communicator", RecordingCommunicator.new)
  machine.communicate.stub_command(
    "ifconfig  | grep 'inet addr:' | grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1 }'",
    "#{ip}\n"
  )

  machine.config.landrush.enable
  machine.config.vm.hostname = hostname


  machine
end

def fake_static_entry(env, hostname, ip)
  env[:global_config].landrush.host(hostname, ip)
  Landrush::Store.hosts.set(hostname, ip)
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
