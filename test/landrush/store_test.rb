require_relative '../test_helper'

module Landrush
  describe Store do
    before do
      @temp_file = Tempfile.new(%w(landrush_test_store .json))
      @store = Store.new(@temp_file)
    end

    after do
      @temp_file.unlink
    end

    describe 'set' do
      it 'sets the key to the value and makes it available for getting' do
        @store.set('foo', 'bar')

        @store.get('foo').must_equal 'bar'
      end

      it 'allows updating keys that already exist' do
        @store.set('foo', 'bar')
        @store.set('foo', 'qux')

        @store.get('foo').must_equal 'qux'
      end
    end

    describe 'get' do
      it 'returns nil for unset values' do
        @store.get('notakey').must_equal nil
      end

      it 'returns the latest set value (no caching)' do
        @store.set('foo', 'first')
        @store.get('foo').must_equal 'first'
        @store.set('foo', 'second')
        @store.get('foo').must_equal 'second'
        @store.delete('foo')
        @store.get('foo').must_equal nil
      end
    end

    describe 'delete' do
      it 'removes the key from the store' do
        @store.set('now', 'you see me')

        @store.get('now').must_equal 'you see me'

        @store.delete('now')

        @store.get('now').must_equal nil # you don't!
      end
    end

    describe 'find' do
      it 'returns the key that matches the end of the search term' do
        @store.set('somehost.vagrant.test', 'here')

        @store.find('foo.somehost.vagrant.test').must_equal 'somehost.vagrant.test'
        @store.find('bar.somehost.vagrant.test').must_equal 'somehost.vagrant.test'
        @store.find('foo.otherhost.vagrant.test').must_equal nil
        @store.find('host.vagrant.test').must_equal nil
      end

      it 'returns exact matches too' do
        @store.set('somehost.vagrant.test', 'here')
        @store.find('somehost.vagrant.test').must_equal 'somehost.vagrant.test'
      end

      it 'returns for prefix searches as well' do
        @store.set('somehost.vagrant.test', 'here')

        @store.find('somehost').must_equal 'somehost.vagrant.test'
        @store.find('somehost.vagrant').must_equal 'somehost.vagrant.test'
        @store.find('somehost.vagr').must_equal nil
        @store.find('someh').must_equal nil
      end
    end

    describe 'clear' do
      it 'clears all keys from the store' do
        @store.set('foo', 'bar')
        @store.set('foo', 'qux')

        @store.clear!

        count = 0
        @store.each do
          count += 1
        end
        count.must_equal 0
      end
    end
  end
end
