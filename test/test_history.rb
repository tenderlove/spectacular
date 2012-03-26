require 'helper'

module Spectacular
  class TestHistory < TestCase
    def test_add
      history = History.new
      history.add "foo", "bar"
      assert_equal "bar", history.last("foo")
    end

    def test_last_2
      history = History.new
      history.add "foo", "bar"
      history.add "foo", "baz"
      assert_equal ["bar", "baz"], history.last("foo", 2)
    end

    def test_all
      history = History.new
      history.add "foo", "bar"
      history.add "foo", "baz"
      assert_equal ['bar', 'baz'], history['foo']
    end

    def test_key_miss
      history = History.new
      history.add "foo", "bar"
      history.add "foo", "baz"
      assert_equal [], history['bar']
      assert_nil history.last 'bar'
      assert_equal [], history.last('bar', 2)
    end
  end
end
