require 'jabber4r/jabber4r'
require 'cerberus/notifier/base'

class Cerberus::Notifier::Jabber < Cerberus::Notifier::Base
  def self.notify(state, build, options)
    begin
      jabber_options = options[:notifier, :jabber]
      subject,body = Cerberus::Notifier::Base.formatted_message(state, build, options)

      session = Jabber::Session.bind(jabber_options[:jid], jabber_options[:password])
      jabber_options[:recipients].split(',').each do |address|
        session.new_message(address.strip).set_subject(subject).set_body(body).send
      end
    ensure
      session.release if session
    end
  end
end
