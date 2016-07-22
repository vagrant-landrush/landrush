module Landrush
  module Cap
    module Ubuntu
      class UbuntuHost < Vagrant.plugin('2', 'host')
        def detect?(_env)
          return false unless Pathname('/usr/bin/lsb_release').exist?
          system("/usr/bin/lsb_release -i | grep 'Ubuntu' >/dev/null 2>&1")
        end
      end
    end
  end
end
