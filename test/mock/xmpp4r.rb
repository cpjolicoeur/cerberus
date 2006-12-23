require 'xmpp4r'

class Jabber::Client
  @@messages = []

  def connect
  end

  def send(message)
    @@messages << message
  end

  def self.messages
    @@messages
  end

  def auth(pwd)
  end
end
