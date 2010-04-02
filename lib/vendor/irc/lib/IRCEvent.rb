require 'yaml'

# This is a lookup class for IRC event name mapping
class EventLookup
  @@lookup = YAML.load_file("#{File.dirname(__FILE__)}/eventmap.yml")

  # returns the event name, given a number
  def EventLookup::find_by_number(num)
    return @@lookup[num.to_i]
  end
end


# Handles an IRC generated event.
# Handlers are for the IRC framework to use
# Callbacks are for users to add.
# Both handlers and callbacks can be called for the same event.
class IRCEvent
  @@handlers = { 'ping' => lambda {|event| IRCConnection.send_to_server("PONG #{event.message}") } }
  @@callbacks = Hash.new()
  attr_reader :hostmask, :message, :event_type, :from, :channel, :target, :mode, :stats
  def initialize (line)
    line.sub!(/^:/, '')
    mess_parts = line.split(':', 2);
    # mess_parts[0] is server info
    # mess_parts[1] is the message that was sent
    @message = mess_parts[1]
    @stats = mess_parts[0].scan(/[-`\^\{\}\[\]\w.\#\@\+]+/)
    if @stats[0].match(/^PING/)
      @event_type = 'ping'
    elsif @stats[1] && @stats[1].match(/^\d+/)
      @event_type = EventLookup::find_by_number(@stats[1]);
      @channel = @stats[3]
    else
      @event_type = @stats[2].downcase if @stats[2]
    end

    if @event_type != 'ping'
      @from    = @stats[0]
      @user    = IRCUser.create_user(@from)
    end
    # FIXME: this list would probably be more accurate to exclude commands than to include them
    @hostmask = @stats[1] if %W(topic privmsg join).include? @event_type
    @channel = @stats[3] if @stats[3] && !@channel
    @target  = @stats[5] if @stats[5]
    @mode    = @stats[4] if @stats[4]
    if @mode.nil? && @event_type == 'mode'
      # Server modes (like +i) are sent in the 'message' part, and not
      # the 'stat' part of the message.
      @mode = @message
    end

    # Unfortunatly, not all messages are created equal. This is our
    # special exceptions section
    if @event_type == 'join'
      @channel = @message
    end

  end

  # Adds a callback for the specified irc message.
  def IRCEvent.add_callback(message_id, &callback)
    @@callbacks[message_id] = callback
  end

  # Adds a handler to the handler function hash.
  def IRCEvent.add_handler(message_id, proc=nil, &handler)
    if block_given?
      @@handlers[message_id] = handler
    elsif proc
      @@handlers[message_id] = proc
    end
  end

  # Process this event, preforming which ever handler and callback is specified
  # for this event.
  def process
    handled = nil
    if @@handlers[@event_type]
      @@handlers[@event_type].call(self)
      handled = 1
    end
    if @@callbacks[@event_type]
      @@callbacks[@event_type].call(self)
      handled = 1
    end
    if !handled
    end
  end
end

