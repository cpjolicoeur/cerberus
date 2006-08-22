require File.dirname(__FILE__) + '/test_helper'

require 'cerberus/publisher/mail'
require 'mock/manager'

class MailPublisherTest < Test::Unit::TestCase
  def setup
    ActionMailer::Base.deliveries.clear
  end

  def test_publisher
    options = Cerberus::Config.new(nil, :publisher => {
       :mail => {:recipients => 'anatol.pomozov@hello.com', :sender => 'haha', :delivery_method => 'test'}}, 
       :application_name => 'MyApp')
    build = DummyManager.new('last message', 'this is output', 1232, 'anatol')

    Cerberus::Publisher::Mail.publish(:setup, build, options)

    mails = ActionMailer::Base.deliveries
    assert_equal 1, mails.size
    mail = mails[0]
    assert_equal 'haha', mail.from_addrs[0].address
    assert_equal '[MyApp] Cerberus set up for project (#1232)', mail.subject
  end
end
