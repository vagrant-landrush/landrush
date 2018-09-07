require_relative '../test_helper'

module Landrush
  describe Store do
    before do
      @temp_file = Tempfile.new(%w[landrush_test_store .json])
    end

    after do
      @temp_file.unlink
    end

    def parallel(thread_count = 10)
      Timeout.timeout(5) do
        (1..thread_count).map do |n|
          Thread.new do
            store = Store.new(@temp_file)
            yield(store, n)
          end
        end.map(&:join)
      end
    end

    describe 'parallel store use' do
      it 'sets the key to the value and makes it available for getting' do
        thread_count = 10
        parallel(thread_count) do |store, n|
          store.set("foo-#{n}", "bar-#{n}")
          sleep 0.1
          assert_equal(store.get("foo-#{n}"), "bar-#{n}")
        end

        store = Store.new(@temp_file)
        (1..thread_count).each do |n|
          assert_equal(store.get("foo-#{n}"), "bar-#{n}")
        end
      end

      it 'lock timeout throws Vagrant error' do
        file = File.open(@temp_file)
        file.flock(File::LOCK_EX)

        assert_raises Landrush::ConfigLockError do
          store = Store.new(@temp_file)
          store.set('foo', 'bar')
        end
      end
    end
  end
end
