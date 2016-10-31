module Landrush
  class Command < Vagrant.plugin('2', :command)
    DAEMON_COMMANDS = %w(start stop restart status).freeze

    def self.synopsis
      'manages DNS for both guest and host'
    end

    def execute
      # Make sure we use the right data directory for Landrush
      Server.working_dir = File.join(@env.data_dir, 'landrush')
      Server.gems_dir = File.join(@env.gems_path, 'gems')
      Server.ui = @env.ui

      ARGV.shift # flush landrush from ARGV
      command = ARGV.first || 'help'
      if DAEMON_COMMANDS.include?(command)
        Server.send(command)
      elsif command == 'dependentvms' || command == 'vms'
        dependent_vms
      elsif command == 'ls' || command == 'list'
        store_ls
      elsif command == 'set'
        store_set
      elsif command == 'del' || command == 'rm'
        store_del
      elsif command == 'help'
        @env.ui.info(help)
      else
        boom("'#{command}' is not a command")
      end

      0 # happy exit code
    end

    def boom(msg)
      raise Vagrant::Errors::CLIInvalidOptions, help: usage(msg)
    end

    def usage(msg); <<-EOS.gsub(/^      /, '')
      ERROR: #{msg}

      #{help}
      EOS
    end

    def help; <<-EOS.gsub(/^      /, '')
      vagrant landrush <command>

      commands:
        {start|stop|restart|status}
          control the landrush server daemon
        list, ls
          list all DNS entries known to landrush
        dependentvms, vms
          list vms currently dependent on the landrush server
        set { <host> <ip> | <alias> <host> }
          adds the given host-to-ip or alias-to-hostname mapping.
          Existing host ip addresses will be overwritten
        rm, del { <host> | <alias> | --all }
          delete the given hostname or alias from the server.
          --all removes all entries
        help
          you're lookin at it!
      EOS
    end

    private

    def dependent_vms
      if DependentVMs.any?
        @env.ui.info(DependentVMs.list.map { |dvm| " - #{dvm}" }.join("\n"))
      else
        @env.ui.info('No dependent VMs')
      end
    end

    def store_del
      key = ARGV[1]
      if key == '--all'
        Landrush::Store.hosts.clear!
      else
        Landrush::Store.hosts.delete(key)
      end
    end

    def store_set
      host, ip = ARGV[1, 2]
      Landrush::Store.hosts.set(host, ip)
    end

    def store_ls
      Landrush::Store.hosts.each do |key, value|
        printf "%-30s %s\n", key, value
      end
    end
  end
end
