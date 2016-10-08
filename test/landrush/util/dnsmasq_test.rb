require_relative '../../test_helper'

module Landrush
  module Util
    describe Dnsmasq do
      MANAGED_DNSMASQ = '# Configuration file for NetworkManager.
[main]
dns=dnsmasq

[logging]
'.split('\n')

      UNMANAGED_DNSMASQ = '# Configuration file for NetworkManager.
[main]
#dns=dnsmasq

[logging]
'.split('\n')

      describe 'nm_managed?' do
        it 'No NetworkManager config exists' do
          File.expects(:exist?).returns(false)
          Dnsmasq.nm_managed?.must_equal false
        end

        it 'NetworkManager manages dnsmasq' do
          File.expects(:exist?).returns(true)
          File.expects(:readlines).returns(MANAGED_DNSMASQ)

          Dnsmasq.nm_managed?.must_equal true
        end

        it 'NetworkManager does not manage dnsmasq' do
          File.expects(:exist?).returns(true)
          File.expects(:readlines).returns(UNMANAGED_DNSMASQ)

          Dnsmasq.nm_managed?.must_equal false
        end
      end
    end
  end
end
