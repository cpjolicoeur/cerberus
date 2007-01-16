require File.dirname(__FILE__) + '/test_helper'

require 'cerberus/publisher/rss'
require 'mock/manager'
require 'tempfile'

class RSSPublisherTest < Test::Unit::TestCase
  def test_publisher
    rss_file = Tempfile.new('cerberus-rss')
    options = Cerberus::Config.new(nil, :publisher => {:rss => {:file => rss_file.path}}, :application_name => 'RSS<App')
    build = DummyManager.new('last message', 'this is output', 1235, 'anatol')

    Cerberus::Publisher::RSS.publish(build_status(false), build, options)

    xml = REXML::Document.new(IO.read(rss_file.path))

    assert_equal '[RSS<App] Build still broken (#1235)', xml.elements["rss/channel/item/title/"].get_text.value
    assert_match %r{<pre>last message\nthis is output\n--\nCerberus 0.\d.\d, http://cerberus.rubyforge.org/</pre>}, 
                     xml.elements["rss/channel/item/description/"].get_text.value
  end
end
