require 'cerberus/publisher/base'

class Cerberus::Publisher::RSS < Cerberus::Publisher::Base
  def self.publish(state, build, options)
    config = options[:publisher, :rss]
    subject,body = Cerberus::Publisher::Base.formatted_message(state, build, options)

    pub_date = Time.now.iso8601
    result = <<-END
<rss version="2.0">
  <channel>
    <title>Cerberus build feed for #{options[:application_name]}</title>
    <pubDate>#{pub_date}</pubDate>
    <generator>http://rubyforge.org/projects/cerberus</generator>
    <item>
      <title>#{subject}</title>
      <pubDate>#{pub_date}</pubDate>
      <description><pre>#{body}</pre></description>
    </item>
  </channel>
</rss>
    END

    File.open(config[:file], 'w'){|f| f.write(result)}
  end
end
