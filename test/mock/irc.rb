class IRCConnection
  @@messages = []
  @@connected = false

  def self.messages
    @@messages
  end

  def self.connected
    @@connected
  end

  def self.send_to_server(msg)
    @@messages << msg
  end

  def self.handle_connection(server, port, nick, realname)
    @@connected = true
  end
end
