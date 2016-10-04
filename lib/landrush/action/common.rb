module Landrush
  module Action
    # A module containing shared functionality for Vagrant middleware classes
    module Common
      SUPPORTED_PROVIDERS = {
        'VagrantPlugins::ProviderVirtualBox::Provider' => :virtualbox,
        'VagrantPlugins::ProviderLibvirt::Provider'    => :libvirt,
        'HashiCorp::VagrantVMwarefusion::Provider'     => :vmware_fusion,
        'VagrantPlugins::Parallels::Provider'          => :parallels,
        'VagrantPlugins::HyperV::Provider'             => :hyperv,
        'Landrush::FakeProvider'                       => :fake_provider
      }.freeze

      def self.included(base)
        base.send :attr_reader, :app, :env
      end

      def initialize(app, env)
        @app = app
        @env = env
      end

      def virtualbox?
        provider == :virtualbox
      end

      def libvirt?
        provider == :libvirt
      end

      def vmware?
        provider == :vmware_fusion
      end

      def parallels?
        provider == :parallels
      end

      def provider
        provider_name = SUPPORTED_PROVIDERS.fetch(machine.provider.class.name) do |key|
          raise "The landrush plugin does not support the #{key} provider yet!"
        end

        if provider_name == :parallels && Gem::Version.new(VagrantPlugins::Parallels::VERSION) < Gem::Version.new('1.0.3')
          raise "The landrush plugin supports the Parallels provider v1.0.3 and later. Please, update your 'vagrant-parallels' plugin."
        end

        provider_name
      end

      def machine
        env[:machine]
      end

      def config
        if env.key? :global_config
          # < Vagrant 1.5
          env[:global_config].landrush
        else
          # >= Vagrant 1.5
          machine.config.landrush
        end
      end

      def machine_hostname
        @machine_hostname ||= read_machine_hostname
      end

      def read_machine_hostname
        return machine.config.vm.hostname if machine.config.vm.hostname

        "#{Pathname.pwd.basename}.#{config.tld}"
      end

      def enabled?
        config.enabled?
      end

      def guest_redirect_dns?
        config.guest_redirect_dns?
      end

      def info(msg)
        env[:ui].info "[landrush] #{msg}"
      end

      def log(level, msg)
        # Levels from github.com/mitchellh/vagrant/blob/master/lib/vagrant/ui.rb
        valid_levels = [:ask, :detail, :warn, :error, :info, :output, :success]

        if valid_levels.include? level
          env[:ui].send level, "[landrush] #{msg}"
        else
          env[:ui].error "[landrush] (Invalid logging level #{level}) #{msg}"
        end
      end
    end
  end
end
