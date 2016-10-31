$LOAD_PATH.push(File.expand_path('../../lib', __FILE__))

require 'bundler/setup'
require 'minitest/spec'

require 'landrush'
require 'landrush/cap/guest/linux/configured_dns_servers'
require 'landrush/cap/guest/linux/redirect_dns'
require 'landrush/cap/guest/all/read_host_visible_ip_address'
require 'landrush/cap/host/darwin/configure_visibility_on_host'
require 'landrush/cap/host/windows/configure_visibility_on_host'
require 'landrush/cap/host/linux/configure_visibility_on_host'
require 'landrush/util/retry'

require 'minitest/autorun'
require 'mocha/mini_test'

# Make sure to keep the numbering sequential here
# Putting include/exclude out of order is kind of the point though ;)
def fake_addresses
  [
    { 'name' => 'ipv6empty1', 'ipv4' => '172.28.128.10', 'ipv6' => '' },
    { 'name' => 'ipv4empty1', 'ipv4' => '',              'ipv6' => '::10' },
    { 'name' => 'ipv6empty2', 'ipv4' => '172.28.128.11', 'ipv6' => '' },
    { 'name' => 'ipv4empty2', 'ipv4' => '',              'ipv6' => '::11' },
    { 'name' => 'exclude1',   'ipv4' => '172.28.128.1',  'ipv6' => '::1' },
    { 'name' => 'include1',   'ipv4' => '172.28.128.2',  'ipv6' => '::2' },
    { 'name' => 'include2',   'ipv4' => '172.28.128.3',  'ipv6' => '::3' },
    { 'name' => 'include3',   'ipv4' => '172.28.128.4',  'ipv6' => '::4' },
    { 'name' => 'exclude2',   'ipv4' => '172.28.128.5',  'ipv6' => '::5' },
    { 'name' => 'exclude3',   'ipv4' => '172.28.128.6',  'ipv6' => '::6' }
  ]
end

def fake_environment(options = { enabled: true })
  # For the home_path we want the base Vagrant directory
  vagrant_test_home = Pathname(Landrush::Server.working_dir).parent.parent
  machine = fake_machine(options)
  { machine: machine, ui: FakeUI.new, home_path: vagrant_test_home, gems_path: machine.env.gems_path }
end

# Returns the gem directory for running unit tests
def gem_dir
  `gem environment gemdir`.strip!
end

class FakeUI
  attr_reader :received_detail_messages
  attr_reader :received_info_messages
  attr_reader :received_error_messages

  def initialize
    @received_detail_messages = []
    @received_info_messages = []
    @received_error_messages = []
  end

  def detail(*args)
    @received_detail_messages << args[0]
  end

  def info(*args)
    @received_info_messages << args[0]
  end

  def error(*args)
    @received_error_messages << args[0]
  end
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

  def execute(command)
    commands[:execute] << command
    responses[command].split("\n").each do |line|
      yield(:stdout, "#{line}\n")
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

module Landrush
  class FakeProvider
    def initialize(*args)
    end

    def _initialize(*args)
    end

    def ssh_info
    end

    def state
      @state ||= Vagrant::MachineState.new('fake-state', 'fake-state', 'fake-state')
    end
  end
end

module Landrush
  class FakeConfig
    def landrush
      @landrush_config ||= Landrush::Config.new
    end

    def vm
      VagrantPlugins::Kernel_V2::VMConfig.new
    end
  end
end

def fake_machine(options = {})
  gem_path = Pathname.new(gem_dir)
  env = options.fetch(:env, Vagrant::Environment.new)
  env.stubs(:gems_path).returns(gem_path)
  machine = Vagrant::Machine.new(
    'fake_machine',
    'fake_provider',
    Landrush::FakeProvider,
    'provider_config',
    {}, # provider_options
    env.vagrantfile.config, # config
    Pathname('data_dir'),
    'box',
    env,
    env.vagrantfile
  )

  machine.instance_variable_set('@communicator', RecordingCommunicator.new)

  machine.config.landrush.enabled = options.fetch(:enabled, false)
  machine.config.landrush.host_interface = nil
  machine.config.landrush.host_interface_excludes = [/exclude[0-9]+/]
  machine.config.vm.hostname = options.fetch(:hostname, 'somehost.vagrant.test')

  machine.guest.stubs(:capability).with(:read_host_visible_ip_address).returns(options.fetch(:ip, '1.2.3.4'))

  machine
end

def fake_static_entry(env, hostname, ip)
  env[:machine].config.landrush.host(hostname, ip)
  Landrush::Store.hosts.set(hostname, ip)
end

module MiniTest
  class Spec
    alias hush capture_io
  end
end

# order is important on these
require_relative 'support/create_fake_working_dir'
require_relative 'support/clear_dependent_vms'
require_relative 'support/test_server_daemon'
require_relative 'support/delete_fake_working_dir'
