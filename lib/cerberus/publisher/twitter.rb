require 'rubygems'
require 'cerberus/publisher/base'
require 'cerberus/utils'

class Cerberus::Publisher::Twitter < Cerberus::Publisher::Base
  def self.publish(state, manager, options)
    begin
      require 'twitter'

      twitter_options = options[:publisher, :twitter]
      raise "There is no consumer key/secret info for Twitter publisher" unless twitter_options[:consumer_key] and twitter_options[:consumer_secret]

      subject, body = Cerberus::Publisher::Base.formatted_message(state, manager, options)

      config = {
        consumer_key: twitter_options[:consumer_key],
        consumer_secret: twitter_options[:consumer_secret],
      }
      client = Twitter::REST::Client.new(config)
      client.update(subject)
    rescue Gem::LoadError
      puts "Twitter publisher requires that you install the 'twitter' gem first."
    end
  end
end
