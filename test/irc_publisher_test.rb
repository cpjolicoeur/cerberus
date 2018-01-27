require File.dirname(__FILE__) + '/test_helper'

require 'cerberus/publisher/irc'
require 'cerberus/config'
require 'cerberus/manager'
require 'mock/irc'
require 'mock/manager'

class IRCPublisherTest < Test::Unit::TestCase
  def test_publisher
    options = Cerberus::Config.new(nil, :publisher => {:irc => {:channel => 'cerberus-testing', :server => 'irc.freenode.net'}}, :application_name => 'IrcApp')
    build = DummyManager.new('last message', 'this is output', 1232, 'anatol')

    Cerberus::Publisher::IRC.publish(build_status(true), build, options)

    # assert IRCConnection.connected
    # assert IRCConnection.messages.first.include?('JOIN')
    # assert_equal 7, IRCConnection.messages.size
  end
end
