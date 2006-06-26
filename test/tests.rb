$:.unshift "../lib"

require 'test/unit'
require 'cerberus/cli'

class CerberusTest < Test::Unit::TestCase
  def test_cerberus
    Cerberus::CLI.new('add', 'file:///work/opensource/ruby/~/cerbrepo')
    config = "#{Cerberus::HOME}/config/cerbrepo.yml"
    assert test(?f, config)
    File.rm config
  end
end