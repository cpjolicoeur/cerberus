require File.dirname(__FILE__) + '/test_helper'

require 'cerberus/publisher/irc'
require 'mock/irc'
require 'mock/build'

class IRCPublisherTest < Test::Unit::TestCase
  def test_publisher
    options = Cerberus::Config.new(nil, :publisher => {:irc => {:recipients => '#hello'}}, :application_name => 'IrcApp')
    build = DummyBuild.new('last message', 'this is output', 1232, 'anatol')

    Cerberus::Publisher::IRC.notify(:setup, build, options)

    messages = IRCConnection.messages
    assert_equal 1, messages.size
    assert_equal 'JOIN #hello', messages[0]
  end
end
