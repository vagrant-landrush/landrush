module Landrush
  module Util
    class Retry
      def self.retry(opts = nil)
        opts = { tries: 1 }.merge(opts || {})
        n = 0
        while n < opts[:tries]
          return true if yield
          sleep opts[:sleep].to_f if opts[:sleep]
          n += 1
        end
        false
      end
    end
  end
end
