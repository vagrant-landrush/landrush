# Monkey patch in a prefix for the RExec daemon log lines.
module RExec
  module Daemon
    module Controller
      def self.puts(str)
        Kernel.puts "[landrush] #{str}"
      end
    end
  end
end
