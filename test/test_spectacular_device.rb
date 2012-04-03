require 'helper'

class TestSpectacularDevice < Spectacular::TestCase

  def setup
    super

    @device = Spectacular::Device.new '192.0.2.1', []
    @klass = Spectacular::Device::Klass
  end

  def test_diff
    from = [1, 1, 'en0', '',
            @klass.new('ifInOctets', '2'), @klass.new('ifOutOctets', '3')]
    to   = [1, 1, 'en0', '',
            @klass.new('ifInOctets', '5'), @klass.new('ifOutOctets', '7')]

    result = @device.send :diff, from, to

    expected = [
      1, 1, @klass.new('ifInOctets', 3), @klass.new('ifOutOctets', 4)
    ]

    assert_equal expected, result
  end

  def test_diff_overflow
    from = [1, 1, 'en0', '',
            @klass.new('ifInOctets', '0'),
            @klass.new('ifOutOctets', 2**32 - 100)]
    to   = [1, 1, 'en0', '',
            @klass.new('ifInOctets', '0'),
            @klass.new('ifOutOctets', 7)]

    result = @device.send :diff, from, to

    expected = [
      1, 1, @klass.new('ifInOctets', 0), @klass.new('ifOutOctets', 106)
    ]

    assert_equal expected, result
  end

end
