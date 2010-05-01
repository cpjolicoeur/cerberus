require 'rubygems'
require 'shout-bot'
require 'cerberus/publisher/base'

class Cerberus::Publisher::IRC < Cerberus::Publisher::Base
  def self.publish(state, manager, options)
    irc_options = options[:publisher, :irc]
    raise "There is no channel provided for IRC publisher" unless irc_options[:channel]
    subject,body = Cerberus::Publisher::Base.formatted_message(state, manager, options)
    message = subject + "\n" + '*' * subject.length + "\n" + body

    port             = irc_options[:port] || 6667
    nick             = irc_options[:nick] || 'cerberus'
    server           = irc_options[:server]
    channel          = '#' + irc_options[:channel]
    channel_password = irc_options[:channel_password]
    
    ShoutBot.shout("irc://#{nick}@#{server}:#{port}/#{channel}", channel_password) do |channel|
      message.split("\n").each { |line| channel.say line }
    end
    
  end
end
