module Landrush
  class Command < Vagrant.plugin('2', :command)
    DAEMON_COMMANDS = %w(start stop restart status)

    def execute
      ARGV.shift
      command = ARGV.first
      if DAEMON_COMMANDS.include?(command)
        Server.send(command)
      elsif command == 'dependentvms' || command == 'vms'
        if DependentVMs.any?
          @env.ui.info(DependentVMs.list.map { |dvm| " - #{dvm}" }.join("\n"))
        else
          @env.ui.info("No dependent VMs")
        end
      elsif command == 'ls' || command == 'list'
        IO.popen("/usr/bin/pr -2 -t -a", "w") do |io|
          Landrush::Store.hosts.each do |key, value|
            io.puts "#{key}"
            io.puts "#{value}"
          end
        end
      elsif command == 'help'
        @env.ui.info(help)
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
        help
          you're lookin at it!
      EOS
    end

    def self.executable
      if Bundler::SharedHelpers.in_bundle?
        ['bundle', 'exec', 'vagrant', 'landrush']
      else
        ['vagrant', 'landrush']
      end
    end

    def self.run_sudo(args)
      cmd = ['sudo'] + executable + args
      unless system(*cmd)
        raise "Failed executing `#{cmd.join(' ')}`: #{$?}"
      end
    end

  end
end
