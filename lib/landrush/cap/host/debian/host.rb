module Landrush
  module Cap
    module Debian
      class DebianHost < Vagrant.plugin('2', 'host')
        def detect?(_env)
          return false unless Pathname('/etc/issue').exist?
          system("cat /etc/issue | grep 'Debian' > /dev/null 2>&1")
        end
      end
    end
  end
end
