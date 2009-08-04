# Twitter4R mistakenly uses ActiveSupport extensions 
module TimeParse
  def Time.parse(args)
    Date.parse(args)
  end
end
Time.extend TimeParse

require 'rubygems'
require 'cerberus/publisher/base'
require 'cerberus/utils'

class Cerberus::Publisher::Twitter < Cerberus::Publisher::Base
  def self.publish(state, manager, options)
    begin
      require 'twitter'

      twitter_options = options[:publisher, :twitter]
      raise "There is no login info for Twitter publisher" unless twitter_options[:login] and twitter_options[:password]

      subject,body = Cerberus::Publisher::Base.formatted_message(state, manager, options)

      client = Twitter::Client.new( :login => twitter_options[:login], :password => twitter_options[:password] )
      status = client.status( :post, subject )

    rescue Gem::LoadError
      puts "Twitter publisher requires that you install the 'twitter4r' gem first." 
    end
  end
end
