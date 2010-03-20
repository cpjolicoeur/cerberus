require 'cerberus/publisher/base'
require 'time'
require 'builder'
require 'rss'

class Cerberus::Publisher::RSS < Cerberus::Publisher::Base
  def self.publish(state, manager, options)
    config = options[:publisher, :rss]
    subject,body = Cerberus::Publisher::Base.formatted_message(state, manager, options)

    pub_date = Time.now

    begin
      feed = RSS::Parser.parse(File.read(config[:file]), false)
      raise RSS::Error unless feed
      keep = config[:keep] || 1
      feed.items.slice!(keep -1 ..-1)  # one less than keep value, to make room for the new build
    rescue RSS::Error, Errno::ENOENT
      # if there's no existing file or we can't parse it, start a new one from scratch
      feed = RSS::Maker.make("2.0") do |new_rss|
        new_rss.channel.title = "#{options[:application_name].to_xs} build status"
        new_rss.channel.description = "Cerberus build feed for #{options[:application_name].to_xs}"
        new_rss.channel.generator = "http://rubyforge.org/projects/cerberus"
        new_rss.channel.link = config[:channel_link] || "file://#{config[:file]}"
      end
    end

    # update channel link if we have it explicitly set, otherwise retain existing value
    feed.channel.link = config[:channel_link] unless config[:channel_link].nil?
    feed.channel.pubDate = pub_date

    new_item = RSS::Rss::Channel::Item.new()
    new_item.title = subject
    new_item.pubDate = pub_date
    new_item.description = "<pre>#{body}</pre>"

    feed.items.unshift new_item

    IO.write(config[:file], feed)
  end
end
