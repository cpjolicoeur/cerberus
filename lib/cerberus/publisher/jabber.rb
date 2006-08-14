require 'jabber4r/jabber4r'
require 'cerberus/publisher/base'

class Cerberus::Publisher::Jabber < Cerberus::Publisher::Base
  def self.publish(state, build, options)
    begin
      jabber_options = options[:publisher, :jabber]
      raise "There is no recipients provided for Jabber publisher" unless jabber_options[:recipients]

      subject,body = Cerberus::Publisher::Base.formatted_message(state, build, options)

      session = login(jabber_options[:jid], jabber_options[:password])
      jabber_options[:recipients].split(',').each do |address|
        session.new_message(address.strip).set_subject(subject).set_body(body).send
      end
    ensure
      session.release if session
    end
  end

  def self.login(id_resource, password, register_if_login_fails=true)
    begin
      session = ::Jabber::Session.bind(id_resource, password)
    rescue
      if(register_if_login_fails)
        if(::Jabber::Session.register(id_resource, password))
          Cerberus::Publisher::Jabber.login(id_resource, password, false)
        else
          raise "Failed to register #{id_resource}"
        end
      end
    end
  end
end
