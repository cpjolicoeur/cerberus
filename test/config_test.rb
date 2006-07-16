require 'test_helper'
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
end
