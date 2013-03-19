require 'test_helper'

module VagrantRubydns
  describe Store do
    before { Store.clear! }
    
    describe "set" do
      it "sets the key to the value and makes it available for getting" do
        Store.set('foo', 'bar')

        Store.get('foo').must_equal 'bar'
      end

      it "allows updating keys that already exist" do
        Store.set('foo', 'bar')
        Store.set('foo', 'qux')

        Store.get('foo').must_equal 'qux'
      end
    end

    describe "get" do
      it "returns nil for unset values" do
        Store.get('notakey').must_equal nil
      end

      it "returns the latest set value (no caching)" do
        Store.set('foo', 'first')
        Store.get('foo').must_equal 'first'
        Store.set('foo', 'second')
        Store.get('foo').must_equal 'second'
        Store.delete('foo')
        Store.get('foo').must_equal nil
      end
    end

    describe "delete" do
      it "removes the key from the store" do
        Store.set('now', 'you see me')

        Store.get('now').must_equal 'you see me'

        Store.delete('now')

        Store.get('now').must_equal nil # you don't!
      end
    end
  end
end
