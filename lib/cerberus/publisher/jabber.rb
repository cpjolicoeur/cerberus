require 'jabber4r/jabber4r'
require 'cerberus/publisher/base'

class Cerberus::Publisher::Jabber < Cerberus::Publisher::Base
  def self.notify(state, build, options)
    begin
      jabber_options = options[:publisher, :jabber]
      subject,body = Cerberus::Publisher::Base.formatted_message(state, build, options)

      session = Jabber::Session.bind(jabber_options[:jid], jabber_options[:password])
      jabber_options[:recipients].split(',').each do |address|
        session.new_message(address.strip).set_subject(subject).set_body(body).send
      end
    ensure
      session.release if session
    end
  end
end
