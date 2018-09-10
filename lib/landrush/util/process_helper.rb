module Landrush
  module Util
    # A module containing helper classes for dealing with pid files
    module ProcessHelper
      def write_pid(pid, file)
        file.rewind
        file.truncate(0)
        file.write pid
        file.flush
      end

      def read_pid(file)
        file.rewind
        file.read.to_i
      rescue StandardError
        nil
      end

      def process_status(file)
        running?(file) ? :running : :stopped
      end

      def ensure_path_exits(file_name)
        dirname = File.dirname(file_name)
        FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
      end

      def terminate_process(file)
        pid = read_pid(file)

        # Kill/Term loop - if the daemon didn't die easily, shoot
        # it a few more times.
        attempts = 5
        while running?(file) && attempts > 0
          sig = attempts >= 2 ? 'KILL' : 'TERM'

          puts "Sending #{sig} to process #{pid}..."
          Process.kill(sig, pid)

          attempts -= 1
          sleep 1
        end
      end
    end
  end
end
