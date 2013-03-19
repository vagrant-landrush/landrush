require 'test_helper'

module VagrantRubydns
  describe Config do
    before { Config.clear! }
    
    describe "set" do
      it "sets the key to the value and makes it available for getting" do
        Config.set('foo', 'bar')

        Config.get('foo').must_equal 'bar'
      end

      it "allows updating keys that already exist" do
        Config.set('foo', 'bar')
        Config.set('foo', 'qux')

        Config.get('foo').must_equal 'qux'
      end
    end

    describe "get" do
      it "returns nil for unset values" do
        Config.get('notakey').must_equal nil
      end

      it "returns the latest set value (no caching)" do
        Config.set('foo', 'first')
        Config.get('foo').must_equal 'first'
        Config.set('foo', 'second')
        Config.get('foo').must_equal 'second'
        Config.delete('foo')
        Config.get('foo').must_equal nil
      end
    end

    describe "delete" do
      it "removes the key from the store" do
        Config.set('now', 'you see me')

        Config.get('now').must_equal 'you see me'

        Config.delete('now')

        Config.get('now').must_equal nil # you don't!
      end
    end
  end
end
