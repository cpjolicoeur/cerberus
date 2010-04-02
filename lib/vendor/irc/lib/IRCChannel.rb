require "IRCUser"

# Represents an IRC Channel
class IRCChannel
  def initialize(name)
    @name = name
    @users = Array.new(0)
  end
  attr_reader :name

  # set the topic on this channel
  def topic=(topic)
    @topic = topic
  end

  # get the topic on this channel
  def topic
    if @topic
      return @topic
    end
    return "No Topic set"
  end

  # add a user to this channel's userlist
  def add_user(username)
    @users.push(IRCUser.create_user(username))
  end

  # returns the current user list for this channel
  def users
    @users
  end
end
