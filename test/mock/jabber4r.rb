class Jabber::Session
  def self.bind(jid, password)
    Jabber::Session.new
  end

  def initialize
  end
end

class Jabber::Protocol::Message
  @@messages = []

  def self.messages
    @@messages
  end

  def self.clear
    @@messages = []
  end

  def send
    @@messages << self
  end
end