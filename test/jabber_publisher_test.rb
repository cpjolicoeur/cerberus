require File.dirname(__FILE__) + '/test_helper'

require 'cerberus/publisher/jabber'
require 'mock/xmpp4r'
require 'mock/manager'

class JabberPublisherTest < Test::Unit::TestCase
  def test_publisher
    options = Cerberus::Config.new(nil, :publisher => {:jabber => {:jid=>'from.cerberus@gmail.com', :recipients => ' jit1@google.com, another@google.com '}}, :application_name => 'MegaApp')
    build = DummyManager.new('last message', 'this is output', 1232, 'anatol')

    Cerberus::Publisher::Jabber.publish(build_status(false), build, options)

    messages = Jabber::Client.messages
    assert messages.size > 2
    assert_equal 'google.com', messages[0].to.domain
    assert_equal 'jit1', messages[0].to.node
    assert_equal '[MegaApp] Build still broken (#1232)', messages[0].subject
    assert !messages[0].body.nil?
  end
end
