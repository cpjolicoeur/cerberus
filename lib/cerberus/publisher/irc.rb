require 'IRC'
require 'cerberus/publisher/base'

class Cerberus::Publisher::IRC < Cerberus::Publisher::Base
  def self.publish(state, build, options)
    irc_options = options[:publisher, :irc]
    subject,body = Cerberus::Publisher::Base.formatted_message(state, build, options)
    message = subject + "\n" + '*' * subject.length + "\n" + body


    bot = IRC.new(irc_options[:nick] || 'cerberus', irc_options[:server], irc_options[:port] || 6667)
    IRCEvent.add_callback('endofmotd') { |event| 
      bot.add_channel(irc_options[:recipients]) 
      message.split("\n").each{|line|
        bot.send_message(irc_options[:recipients], line)
      }
      bot.send_quit
    }
    bot.connect
  end
end
