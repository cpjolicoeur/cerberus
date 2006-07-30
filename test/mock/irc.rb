class IRCConnection
  @@messages = []

  def self.messages
    @@messages
  end

  def self.send_to_server(msg)
    @@messages << msg
  end

  def self.handle_connection(server, port)
  end
end
