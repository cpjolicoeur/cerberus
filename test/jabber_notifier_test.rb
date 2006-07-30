require File.dirname(__FILE__) + '/test_helper'

require 'cerberus/notifier/jabber'
require 'mock/jabber4r'
require 'mock/build'

class JabberNotifierTest < Test::Unit::TestCase
  def test_notifier
    options = {:notifier => {:jabber => {:recipients => ' jit1@google.com, another@google.com '}}, :application_name => 'MegaApp'}
    build = DummyBuild.new('last message', 'this is output', 1232, 'anatol')

    Cerberus::Notifier::Jabber.notify(:setup, build, options)

    messages = Jabber::Protocol::Message.messages
    assert_equal 2, messages.size
    assert_equal 'google.com', messages[0].to.host
    assert_equal 'jit1', messages[0].to.node
    assert_equal '[MegaApp] Cerberus set up for project (#1232)', messages[0].subject
  end
end
