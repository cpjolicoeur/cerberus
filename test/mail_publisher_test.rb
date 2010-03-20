require File.dirname(__FILE__) + '/test_helper'

require 'cerberus/publisher/mail'
require 'cerberus/manager'
require 'mock/manager'

class MailPublisherTest < Test::Unit::TestCase
  def setup
    ActionMailer::Base.deliveries.clear
  end

  def test_publisher
    options = Cerberus::Config.new(nil, :publisher => {
       :mail => {:recipients => 'anatol.pomozov@hello.com', :sender => "cerberus@example.com", :delivery_method => 'test'},
       :extra_subject => "[#deployment]"}, 
       :application_name => 'MyApp')
    build = DummyManager.new('last message', 'this is output', 1232, 'anatol')

    Cerberus::Publisher::Mail.publish(build_status(true), build, options)

    mails = ActionMailer::Base.deliveries
    assert_equal 1, mails.size
    mail = mails[0]
    assert_equal 'cerberus@example.com', mail.from_addrs[0].address
    assert_equal '[MyApp][#deployment] Cerberus set up for project (1232)', mail.subject
  end
end
