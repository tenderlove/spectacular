require 'helper'

module Spectacular
  class TestSizedList < TestCase
    def test_first
      list = SizedList.new 10
      11.times { |i| list << i }
      assert_equal 1, list.first
    end

    def test_last
      list = SizedList.new 10
      11.times { |i| list << i }
      assert_equal 10, list.last
    end

    def test_length
      list = SizedList.new 10
      assert_equal 0, list.length
      10.times { |i|
        list << i
        assert_equal(i + 1, list.length)
      }
      list << Object.new
      assert_equal 10, list.length
    end
  end
end
