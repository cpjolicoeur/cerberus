require File.dirname(__FILE__) + '/test_helper'

require 'cerberus/publisher/cerberusweb'
require 'cerberus/manager'
require 'mock/manager'

class CerberusWebPublisherText < Test::Unit::TestCase
  def test_publisher
    options = Cerberus::Config.new(nil, :publisher => {:cerberusweb => {:db_path => './cerberusweb.sqlite'}}, :application_name => 'CerberusWebApp')
    build = DummyManager.new('last message', 'this is output', 1232, 'anatol')

    Cerberus::Publisher::CerberusWeb.publish( build_status(true), build, options)

    # TODO: replace with real tests
    assert true
  end
end
