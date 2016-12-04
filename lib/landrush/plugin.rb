module Landrush
  class Plugin < Vagrant.plugin('2')
    name 'landrush'

    command 'landrush' do
      require_relative 'command'
      Command
    end

    config 'landrush' do
      require_relative 'config'
      Config
    end

    landrush_setup = lambda do |hook|
      require_relative 'action/common'
      require_relative 'action/setup'
      require_relative 'action/install_prerequisites'
      require_relative 'action/redirect_dns'

      # Hooks for VirtualBox and HyperV providers
      hook.before(VagrantPlugins::ProviderVirtualBox::Action::Network, pre_boot_actions)
      hook.before(VagrantPlugins::HyperV::Action::WaitForIPAddress, pre_boot_actions)
      hook.after(Vagrant::Action::Builtin::WaitForCommunicator, post_boot_actions)

      # Hooks for Libvirt provider
      if defined?(VagrantPlugins::ProviderLibvirt)
        hook.after(VagrantPlugins::ProviderLibvirt::Action::CreateNetworks, pre_boot_actions)
        hook.after(VagrantPlugins::ProviderLibvirt::Action::WaitTillUp, post_boot_actions)
      end

      # Hooks for VMWarefusion provider
      if defined?(HashiCorp::VagrantVMwarefusion)
        hook.before(HashiCorp::VagrantVMwarefusion::Action::Network, pre_boot_actions)
        hook.after(HashiCorp::VagrantVMwarefusion::Action::WaitForCommunicator, post_boot_actions)
      end

      # Hooks for Parallels provider
      if defined?(VagrantPlugins::Parallels)
        hook.before(VagrantPlugins::Parallels::Action::Network, pre_boot_actions)
      end
    end

    action_hook 'landrush_setup', :machine_action_up, &landrush_setup
    action_hook 'landrush_setup', :machine_action_reload, &landrush_setup

    def self.pre_boot_actions
      Vagrant::Action::Builder.new.tap do |b|
        b.use Action::Setup
        b.use Action::RedirectDns
      end
    end

    def self.post_boot_actions
      Vagrant::Action::Builder.new.tap do |b|
        b.use Action::InstallPrerequisites
      end
    end

    landrush_teardown = lambda do |hook|
      require_relative 'action/common'
      require_relative 'action/teardown'
      hook.append(Action::Teardown)
    end

    action_hook 'landrush_teardown', :machine_action_halt, &landrush_teardown
    action_hook 'landrush_teardown', :machine_action_destroy, &landrush_teardown
    action_hook 'landrush_teardown', :machine_action_reload, &landrush_teardown

    guest_capability('debian', 'iptables_installed') do
      require_relative 'cap/guest/debian/iptables_installed'
      Cap::Debian::IptablesInstalled
    end

    guest_capability('debian', 'install_iptables') do
      require_relative 'cap/guest/debian/install_iptables'
      Cap::Debian::InstallIptables
    end

    guest_capability('redhat', 'iptables_installed') do
      require_relative 'cap/guest/redhat/iptables_installed'
      Cap::Redhat::IptablesInstalled
    end

    guest_capability('redhat', 'install_iptables') do
      require_relative 'cap/guest/redhat/install_iptables'
      Cap::Redhat::InstallIptables
    end

    guest_capability('suse', 'add_iptables_rule') do
      require_relative 'cap/guest/suse/add_iptables_rule'
      Cap::Suse::AddIptablesRule
    end

    guest_capability('suse', 'iptables_installed') do
      require_relative 'cap/guest/suse/iptables_installed'
      Cap::Suse::IptablesInstalled
    end

    guest_capability('suse', 'install_iptables') do
      require_relative 'cap/guest/suse/install_iptables'
      Cap::Suse::InstallIptables
    end

    guest_capability('linux', 'configured_dns_servers') do
      require_relative 'cap/guest/linux/configured_dns_servers'
      Cap::Linux::ConfiguredDnsServers
    end

    guest_capability('linux', 'redirect_dns') do
      require_relative 'cap/guest/linux/redirect_dns'
      Cap::Linux::RedirectDns
    end

    guest_capability('linux', 'add_iptables_rule') do
      require_relative 'cap/guest/linux/add_iptables_rule'
      Cap::Linux::AddIptablesRule
    end

    guest_capability('linux', 'read_host_visible_ip_address') do
      require_relative 'cap/guest/all/read_host_visible_ip_address'
      Cap::All::ReadHostVisibleIpAddress
    end

    host_capability('darwin', 'configure_visibility_on_host') do
      require_relative 'cap/host/darwin/configure_visibility_on_host'
      Cap::Darwin::ConfigureVisibilityOnHost
    end

    host_capability('windows', 'configure_visibility_on_host') do
      require_relative 'cap/host/windows/configure_visibility_on_host'
      Cap::Windows::ConfigureVisibilityOnHost
    end

    host_capability('linux', 'configure_visibility_on_host') do
      require_relative 'cap/host/linux/configure_visibility_on_host'
      Cap::Linux::ConfigureVisibilityOnHost
    end

    host_capability('linux', 'create_dnsmasq_config') do
      require_relative 'cap/host/linux/create_dnsmasq_config'
      Cap::Linux::CreateDnsmasqConfig
    end

    host 'debian', 'linux' do
      require_relative 'cap/host/debian/host'
      Cap::Debian::DebianHost
    end

    host 'ubuntu', 'debian' do
      require_relative 'cap/host/ubuntu/host'
      Cap::Ubuntu::UbuntuHost
    end

    host_capability('debian', 'dnsmasq_installed') do
      require_relative 'cap/host/debian/dnsmasq_installed'
      Landrush::Cap::Debian::DnsmasqInstalled
    end

    host_capability('debian', 'install_dnsmasq') do
      require_relative 'cap/host/debian/install_dnsmasq'
      Cap::Debian::InstallDnsmasq
    end

    host_capability('debian', 'restart_dnsmasq') do
      require_relative 'cap/host/debian/restart_dnsmasq'
      Cap::Debian::RestartDnsmasq
    end

    host_capability('redhat', 'dnsmasq_installed') do
      require_relative 'cap/host/redhat/dnsmasq_installed'
      Cap::Redhat::DnsmasqInstalled
    end

    host_capability('redhat', 'install_dnsmasq') do
      require_relative 'cap/host/redhat/install_dnsmasq'
      Cap::Redhat::InstallDnsmasq
    end

    host_capability('redhat', 'restart_dnsmasq') do
      require_relative 'cap/host/redhat/restart_dnsmasq'
      Cap::Redhat::RestartDnsmasq
    end

    host_capability('suse', 'dnsmasq_installed') do
      require_relative 'cap/host/suse/dnsmasq_installed'
      Cap::Suse::DnsmasqInstalled
    end

    host_capability('suse', 'install_dnsmasq') do
      require_relative 'cap/host/suse/install_dnsmasq'
      Cap::Suse::InstallDnsmasq
    end

    host_capability('suse', 'restart_dnsmasq') do
      require_relative 'cap/host/suse/restart_dnsmasq'
      Cap::Suse::RestartDnsmasq
    end

    host_capability('arch', 'dnsmasq_installed') do
      require_relative 'cap/host/arch/dnsmasq_installed'
      Cap::Arch::DnsmasqInstalled
    end

    host_capability('arch', 'install_dnsmasq') do
      require_relative 'cap/host/arch/install_dnsmasq'
      Cap::Arch::InstallDnsmasq
    end

    host_capability('arch', 'restart_dnsmasq') do
      require_relative 'cap/host/arch/restart_dnsmasq'
      Cap::Arch::RestartDnsmasq
    end
  end
end
