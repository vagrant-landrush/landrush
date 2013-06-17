module Landrush
  class Command < Vagrant.plugin('2', :command)
    DAEMON_COMMANDS = %w(start stop restart status)
    DEPENDENT_VM_COMMADNS = %w(dependentvms)

    def execute
      ARGV.shift # flush landrush from ARGV, RExec wants to use it for daemon commands

      command = ARGV.first
      if DAEMON_COMMANDS.include?(command)
        Server.daemonize
      elsif command == 'dependentvms'
        if DependentVMs.any?
          @env.ui.info(DependentVMs.list.map { |dvm| " - #{dvm}" }.join("\n"))
        else
          @env.ui.info("No dependent VMs")
        end
      else
        boom("'#{command}' is not a command")
      end

      0 # happy exit code
    end

    def boom(msg)
      raise Vagrant::Errors::CLIInvalidOptions, :help => usage(msg)
    end

    def usage(msg); <<-EOS.gsub(/^      /, '')
      ERROR: #{msg}

      vagrant landrush <command>

      commands:
        {start|stop|restart|status}
          control the landrush server daemon
        dependentvms
          list vms currently dependent on the landrush server
      EOS
    end
  end
end
