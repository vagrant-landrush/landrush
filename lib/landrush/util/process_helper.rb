module Landrush
  module Util
    # A module containing helper classes for dealing with pid files
    module ProcessHelper
      def write_pid(pid, pid_file)
        ensure_path_exits(pid_file)
        File.open(pid_file, 'w') { |f| f << pid.to_s }
      end

      def read_pid(pid_file)
        IO.read(pid_file).to_i
      rescue
        nil
      end

      def delete_pid_file(pid_file)
        FileUtils.rm(pid_file) if File.exist? pid_file
      end

      def process_status(pid_file)
        return running? ? :running : :unknown if File.exist? pid_file
        :stopped
      end

      def ensure_path_exits(file_name)
        dirname = File.dirname(file_name)
        FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
      end

      def terminate_process(pid)
        # Kill/Term loop - if the daemon didn't die easily, shoot
        # it a few more times.
        attempts = 5
        while running? && attempts > 0
          sig = (attempts >= 2) ? 'KILL' : 'TERM'

          puts "Sending #{sig} to process #{pid}..."
          Process.kill(sig, pid)

          attempts -= 1
          sleep 1
        end
      end
    end
  end
end
