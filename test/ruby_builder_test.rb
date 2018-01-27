require_relative 'test_helper'

require 'cerberus/builder/ruby'
require 'tmpdir'

class Cerberus::Builder::Ruby
  attr_writer :output
end

class RubyBuilderTest < Test::Unit::TestCase
  def setup
    tmp = Dir::tmpdir
    @cfg = Cerberus::Config.new(nil, {:application_root => tmp})
  end

  def test_builder
    @cfg.merge!(:builder => {:ruby => {:success => 'Build successful', :failure => 'Build failed', :brokeness => '(\d+) failures, (\d+) errors'}})
    builder = Cerberus::Builder::Ruby.new(@cfg)

    builder.output = SUCCESS_OUTPUT
    assert builder.successful?

    builder.output = FAILURE_OUTPUT
    assert !builder.successful?
    assert_equal 10, builder.brokeness

    @cfg.merge!(:builder => {:ruby => {:success => 'Build successful', :failure => '[Build] FAILURE', :brokeness => '(\d+) failures, (\d+) errors, (\d+) huge problems'}})
    builder.output = CUSTOM_FAILURE_OUTPUT
    assert !builder.successful?
    assert_equal 19, builder.brokeness
  end

  def test_builder_without_custom_config
    @cfg.merge!(:builder => {:ruby => {}})
    builder = Cerberus::Builder::Ruby.new(@cfg)

    builder.output = DEFAULT_SUCCESS_OUTPUT
    assert builder.successful?
    assert_equal 0, builder.brokeness
  end
end

SUCCESS_OUTPUT = <<-END
A
Bunch
Of 
Output
Build successful
END

DEFAULT_SUCCESS_OUTPUT = <<-END
A
Bunch of
Output
23 tests, 46 assertions, 0 failures, 0 errors
END

FAILURE_OUTPUT = <<-END
A
Bunch
Of 
Output
Build failed
7 failures, 3 errors
END

CUSTOM_FAILURE_OUTPUT = <<-END
A
Bunch
Of 
Output
[Build] FAILURE
7 failures, 3 errors, 9 huge problems
END
