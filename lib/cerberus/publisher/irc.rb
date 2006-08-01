require 'IRC'
require 'cerberus/publisher/base'

class Cerberus::Publisher::IRC < Cerberus::Publisher::Base
  def self.notify(state, build, options)
    irc_options = options[:publisher, :irc]
    subject,body = Cerberus::Publisher::Base.formatted_message(state, build, options)
    message = subject + "\n" + '*' * subject.length + "\n" + body

    bot = IRC.new(irc_options[:nick], irc_options[:serevr], irc_options[:port], 'Cerberus continuous builder').add_channel(irc_options[:recipients])
    IRCEvent.add_callback('join') {|event|
      bot.send_message(event.channel, message)
    }
    bot.connect
  end
end
