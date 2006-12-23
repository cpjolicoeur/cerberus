require 'rubygems'
require 'xmpp4r'
require 'cerberus/publisher/base'

class Cerberus::Publisher::Jabber < Cerberus::Publisher::Base
  def self.publish(state, manager, options)
    begin
      jabber_options = options[:publisher, :jabber]
      raise "There is no recipients provided for Jabber publisher" unless jabber_options[:recipients]

      subject,body = Cerberus::Publisher::Base.formatted_message(state, manager, options)

      client = Jabber::Client::new(Jabber::JID.new(jabber_options[:jid]))
      client.connect
      client.auth(jabber_options[:password])

      jabber_options[:recipients].split(',').each do |address|
        message = Jabber::Message::new(address.strip, body).set_subject(subject)
        client.send(message)
      end
    ensure
      client.close if client
    end
  end
end
