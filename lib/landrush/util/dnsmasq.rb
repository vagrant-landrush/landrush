module Landrush
  module Util
    class Dnsmasq
      def self.nm_managed?
        nm_config = Pathname('/etc/NetworkManager/NetworkManager.conf')
        File.exist?(nm_config) && File.readlines(nm_config).grep(/^dns=dnsmasq$/).any?
      end
    end
  end
end
