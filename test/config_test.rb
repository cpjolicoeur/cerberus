require File.dirname(__FILE__) + '/test_helper'

require 'cerberus/config'

class ConfigTest < Test::Unit::TestCase
  def test_config
    dump_yml(HOME + "/config.yml", {'a'=>'conf', 'd'=>'conf', 'm' => 'conf'})
    dump_yml(HOME + "/config/abra.yml", {'a'=>'app', 'd'=>'app', 'g' => 'app'})
    cfg = Cerberus::Config.new('abra', :a => 'cli', :b=>'cli', :e=>'cli')

    assert_equal nil, cfg[:mamba]
    assert_equal 'cli', cfg[:a]
    assert_equal 'cli', cfg[:b]
    assert_equal 'app', cfg[:d]
    assert_equal 'app', cfg[:g]
    assert_equal 'conf', cfg[:m]

  
    assert_equal nil, cfg['mamba']
    assert_equal 'cli', cfg['a']
    assert_equal 'cli', cfg['b']
    assert_equal 'app', cfg['d']
    assert_equal 'app', cfg['g']
    assert_equal 'conf', cfg['m']
  end

  def test_deep_merge
    cfg = Cerberus::Config.new
    cfg.merge!(:hello => {'msg' => {:a202 => 'bye'}})
    cfg.merge!(:hello => {:msg => {:a203 => 'hello'}})
    cfg.merge!(:hello => {:msg => {:a204 => 'another'}})
    cfg.merge!(:hello => {:bread => {:a204 => 'bread'}})

    assert_equal 'bye', cfg[:hello, :msg, :a202]
    assert_equal 'hello', cfg[:hello, :msg, :a203]
    assert_equal 'bread', cfg[:hello, :bread, :a204]
  end
end
