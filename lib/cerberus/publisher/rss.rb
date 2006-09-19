require 'cerberus/publisher/base'
require 'cerberus/helper/xchar.rb'

class Cerberus::Publisher::RSS < Cerberus::Publisher::Base
  def self.publish(state, manager, options)
    config = options[:publisher, :rss]
    subject,body = Cerberus::Publisher::Base.formatted_message(state, manager, options)

    pub_date = Time.now.iso8601
    description = "<pre>#{body}</pre>".to_xs
    result = <<-END
<rss version="2.0">
  <channel>
    <title>Cerberus build feed for #{options[:application_name].to_xs}</title>
    <pubDate>#{pub_date}</pubDate>
    <generator>http://rubyforge.org/projects/cerberus</generator>
    <item>
      <title>#{subject.to_xs}</title>
      <pubDate>#{pub_date}</pubDate>
      <description>#{description}</description>
    </item>
  </channel>
</rss>
    END

    IO.write(config[:file], result)
  end
end
