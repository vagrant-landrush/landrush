require_relative '../../test_helper'

class DummyClass
  include Landrush::Util::Retry
end

module Landrush
  module Util
    describe Retry do
      before do
        @dummy = DummyClass.new
      end

      describe 'retry' do
        it 'retries the provided block up to the specified count' do
          retries = 0
          result = @dummy.retry(tries: 2) do
            retries += 1
            false
          end
          retries.must_equal 2
          result.must_equal false
        end

        it 'does not retry if \'true\' is returned' do
          retries = 0
          result = @dummy.retry(tries: 2) do
            retries += 1
            true
          end
          retries.must_equal 1
          result.must_equal true
        end

        it 'does sleep between executions if requested' do
          retries = 0
          t1 = Time.now
          result = @dummy.retry(tries: 1, sleep: 1) do
            retries += 1
            false
          end
          t2 = Time.now
          retries.must_equal 1
          result.must_equal false
          assert t2 - t1 > 1
        end
      end
    end
  end
end
