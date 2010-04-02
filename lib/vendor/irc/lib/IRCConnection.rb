
# Handles connection to IRC Server
class IRCConnection
  @@quit          = 0
  @@readsockets   = Array.new(0)
  @@output_buffer = Array.new(0)
  @@events        = Hash.new()
  @@last_send     = Time.now.to_f
  @@message_delay = 0.2 # Default delay to 1 fifth of a second.
  # Creates a socket connection and then yields.
  def IRCConnection.handle_connection(server, port, nick='ChangeMe', realname='MeToo', options = nil)
    @server = server;
    @port = port
    @nick = nick
    @realname = realname
    @@options = options
    if options.nil?
      @@options = Array.new(0)
    end
    socket = create_tcp_socket(server, port)
    add_IO_socket(socket) {|sock|
      begin
        IRCEvent.new(sock.readline.chomp)
      rescue Errno::ECONNRESET
        # Catches connection reset by peer, attempts to reconnect
        # after sleeping for 10 second.
        remove_IO_socket(sock)
        sleep 10
        handle_connection(@server, @port, @nick, @realname, @@options)
      end
    }
    send_to_server "NICK #{nick}"
    send_to_server "USER #{nick} 8 * :#{realname}"
    if block_given?
      yield
      @@socket.close
    end
  end

  def IRCConnection.create_tcp_socket(server, port)
    # Now with SSL Support. Thanks to dominiek@digigen.nl for the idea on this.
    tcpsocket = TCPsocket.open(server, port)
    if @@options[:use_ssl]
      ssl_context = OpenSSL::SSL::SSLContext.new()
      ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      @@socket = OpenSSL::SSL::SSLSocket.new(tcpsocket, ssl_context)
      @@socket.sync = true
      @@socket.connect
    else
      @@socket = tcpsocket
    end

    if block_given?
      yield
      @@socket.close
      return
    end
    return @@socket
  end

  # Sends a line of text to the server
  def IRCConnection.send_to_server(line)
    @@socket.write(line + "\n")
  end

  # Adds data an output buffer. This let's us keep a handle on how
  # fast we send things. Yay.
  def IRCConnection.output_push(line)
    @@output_buffer.push(line)
  end

  # This loop monitors all IO_Sockets IRCConnection controls
  # (including the IRC socket) and yields events to the IO_Sockets
  # event handler.
  def IRCConnection.main
    while(@@quit == 0)
      do_one_loop { |event|
        yield event
      }
    end
  end

  # Makes one single loop pass, checking all sockets for data to read,
  # and yields the data to the sockets event handler.
  def IRCConnection.do_one_loop
    read_sockets = select(@@readsockets, nil, nil, 0.1);
    if !read_sockets.nil?
      read_sockets[0].each {|sock|
        if sock.eof? && sock == @@socket
          remove_IO_socket(sock)
          sleep 10
          handle_connection(@server, @port, @nick, @realname)
        else
          yield @@events[sock.object_id.to_i].call(sock)
        end
      }
    end
    if @@output_buffer.length > 0
      timer = Time.now.to_f
      if (timer > @@last_send + @@message_delay)
        message = @@output_buffer.shift();
        if !message.nil?
          IRCConnection.send_to_server(message);
          @@last_send = timer
        end
      end
    end
  end

  # Ends connection to the irc server
  def IRCConnection.quit
    @@quit = 1
  end
  def IRCConnection.delay=(delay)
    @@message_delay = delay.to_f
  end
  # Retrieves user info from the server
  def IRCConnection.get_user_info(user)
    IRCConnection.send_to_server("WHOIS #{user}")
  end

  # Adds a new socket to the list of sockets to monitor for new data.
  def IRCConnection.add_IO_socket(socket, &event_generator)
    @@readsockets.push(socket)
    @@events[socket.object_id.to_i] = event_generator
  end

  def IRCConnection.remove_IO_socket(sock)
    sock.close
    @@readsockets.delete_if {|item| item == sock }
  end
end


