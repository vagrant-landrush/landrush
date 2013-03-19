module VagrantRubydns
  class Plugin < Vagrant.plugin('2')
    name 'vagrant-rubydns'

    command 'rubydns' do
      require_relative 'command'
      Command
    end

    config 'rubydns' do
      require_relative 'config'
      Config
    end

    provisioner 'rubydns' do
      require_relative 'provisioner'
      Provisioner
    end

    action_hook 'rubydns_setup', :machine_action_up do |hook|
      require_relative 'action/setup'
      hook.before(VagrantPlugins::ProviderVirtualBox::Action::Boot, Action::Setup)
    end

    action_hook 'rubydns_teardown', :machine_action_halt do |hook|
      require_relative 'action/teardown'
      hook.after(Vagrant::Action::Builtin::GracefulHalt, Action::Teardown)
    end
  end
end
