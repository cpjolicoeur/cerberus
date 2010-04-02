
require 'socket'
require 'IRCConnection'
require 'IRCEvent'
require 'IRCChannel'
require 'IRCUser'
require 'IRCUtil'



# Class IRC is a master class that handles connection to the irc
# server and pasring of IRC events, through the IRCEvent class.
class IRC
  @channels = nil
  # Create a new IRC Object instance
  def initialize( nick, server, port, realname='RBot', options = {})
    @nick = nick
    @server = server
    @port = port
    @realname = realname
    @channels = Array.new(0)
    # Some good default Event handlers. These can and will be overridden by users.
    # Thses make changes on the IRCbot object. So they need to be here.

    # Topic events can come on two tags, so we create one proc to handle them.
    topic_proc = Proc.new { |event|
      self.channels.each { |chan|
        if chan == event.channel
          chan.topic = event.message
        end
      }
    }

    IRCEvent.add_handler('332', topic_proc)
    IRCEvent.add_handler('topic', topic_proc)
    @@options = options;

  end

  attr_reader :nick, :server, :port

  # Join a channel, adding it to the list of joined channels
  def add_channel channel
    join(channel)
    self
  end

  # Returns a list of channels joined
  def channels
    @channels
  end

  # Alias for IRC.connect
  def start
    self.connect
  end

  # Open a connection to the server using the IRC Connect
  # method. Events yielded from the IRCConnection handler are
  # processed and then control is returned to IRCConnection
  def connect
    quithandler = lambda { send_quit(); IRCConnection.quit }
    trap("INT", quithandler)
    trap("TERM", quithandler)

    IRCConnection.handle_connection(@server, @port, @nick, @realname, @@options) do
      # Log in information moved to IRCConnection
      @threads = []
      IRCConnection.main do |event|
        if event.kind_of?(Array)
          event.each {|event|
            thread_event(event)
          }
        else
          thread_event(event)
        end
        # Memory leak patch thanks to Patrick Sinclair
        @threads.delete_if {|thr| thr.stop? }
      end
      @threads.each {|thr| thr.join }
    end
  end

  # Joins a channel on a server.
  def join(channel)
    if (IRCConnection.send_to_server("JOIN #{channel}"))
      @channels.push(IRCChannel.new(channel));
    end
  end

  # Leaves a channel on a server
  def part(channel)
    if (IRCConnection.send_to_server("PART #{channel}"))
      @channels.delete_if {|chan| chan.name == channel }
    end
  end

  # kicks a user from a channel (does not check for operator privledge)
  def kick(channel, user, message)
    IRCConnection.send_to_server("KICK #{channel} #{user} :#{message || user || 'kicked'}")
  end

  # sets the topic of the given channel
  def set_topic(channel, topic)
    IRCConnection.send_to_server("TOPIC #{channel} :#{topic}");
  end

  # Sends a private message, or channel message
  def send_message(to, message)
    IRCConnection.send_to_server("privmsg #{to} :#{message}");
  end

  # Sends a notice
  def send_notice(to, message)
    IRCConnection.send_to_server("NOTICE #{to} :#{message}");
  end

  # performs an action
  def send_action(to, action)
    send_ctcp(to, 'ACTION', action);
  end

  # send CTCP
  def send_ctcp(to, type, message)
    IRCConnection.send_to_server("privmsg #{to} :\001#{type} #{message}");
  end

  # Quits the IRC Server
  def send_quit
    IRCConnection.send_to_server("QUIT : Quit ordered by user")
  end

  # Ops selected user.
  def op(channel, user)
    IRCConnection.send_to_server("MODE #{channel} +o #{user}")
  end

  # Changes the current nickname
  def ch_nick(nick)
    IRCConnection.send_to_server("NICK #{nick}")
    @nick = nick
  end

  # Removes operator status from a user
  def deop(channel, user)
    IRCConnection.send_to_server("MODE #{channel} -o #{user}")
  end

  # Changes target users mode
  def mode(channel, user, mode)
    IRCConnection.send_to_server("MODE #{channel} #{mode} #{user}")
  end

  # Retrievs user information from the server
  def get_user_info(user)
    IRCConnection.send_to_server("WHO #{user}")
  end
  private
  def thread_event (event)
    @threads << Thread.new(event) {|localevent|
      localevent.process
    }
  end
end
