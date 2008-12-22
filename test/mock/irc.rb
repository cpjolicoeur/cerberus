class IRCConnection
  @@messages = []
  @@connected = false

  class << self
    def messages
      @@messages
    end

    def connected
      @@connected
    end

    def send_to_server(msg)
      if msg =~ /QUIT/
        @@connected = false
      else
        @@messages << msg
      end
    end

    def handle_connection(server, port, nick, realname, options)
      @@connected = true
    end
  end
end

class IRCEvent
  class << self
    def add_callback(msg_id, &callback)
      yield
    end
  end
end
