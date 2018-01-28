require_relative 'test_helper'

require 'cerberus/utils'

class CronStringTest < Test::Unit::TestCase
  def test_simple_number
    assert "1".cron_match?(1)
  end

  def test_star
    assert "*".cron_match?(0)
    assert "*".cron_match?(1000)
  end

  def test_not_match_simple
    assert_equal false, "1".cron_match?(2)
  end

  def test_separate_numbers
    str = "1,3,5"
    assert str.cron_match?(1)
    assert str.cron_match?(3)
    assert str.cron_match?(5)
    assert(!str.cron_match?(0))
    assert(!str.cron_match?(2))
    assert(!str.cron_match?(4))
    assert(!str.cron_match?(6))
  end

  def test_range
    str = "2-4"
    assert(!str.cron_match?(1))
    assert str.cron_match?(2)
    assert str.cron_match?(3)
    assert str.cron_match?(4)
    assert(!str.cron_match?(5))
  end

  def test_comma_and_range
    str = "3-4,7-8"
    assert(!str.cron_match?(2))
    assert str.cron_match?(3)
    assert str.cron_match?(4)
    assert(!str.cron_match?(5))
    assert(!str.cron_match?(6))
    assert str.cron_match?(7)
    assert str.cron_match?(8)
    assert(!str.cron_match?(9))
  end

  def test_divisor
    str = "1-6/2"
    assert(!str.cron_match?(0))
    assert str.cron_match?(1)
    assert(!str.cron_match?(2))
    assert str.cron_match?(3)
    assert(!str.cron_match?(4))
    assert str.cron_match?(5)
    assert(!str.cron_match?(6))
  end

  def test_garble
    assert(!"1,x".cron_match?(6))
    assert(!",".cron_match?(6))
    assert(!"x".cron_match?(6))
    assert(!"1-10/x".cron_match?(6))
    assert(!"~-10/2".cron_match?(6))
  end

  def test_star_and_divisor
    str = "*/3"
    assert str.cron_match?(0)
    assert(!str.cron_match?(1))
    assert(!str.cron_match?(2))
    assert str.cron_match?(3)
    assert(!str.cron_match?(4))
    assert(!str.cron_match?(5))
    assert str.cron_match?(6)
    assert str.cron_match?(9)
    assert str.cron_match?(12)
    assert str.cron_match?(129)
  end

  def test_star_with_letters
    assert(!"*".cron_match?('A'))
  end

  def test_star_in_wrong_place
    assert(!"*-12".cron_match?('1'))
    assert(!"*-12/2".cron_match?('2'))
  end
end
