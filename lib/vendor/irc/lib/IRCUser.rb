# Represents IRC Users
class IRCUser
  @@users = Hash.new()
  @modes = Hash.new()

  def IRCUser.create_user(username)
    username.sub!(/^[\@\%]/,'')

    if @@users[username]
      return @@users[username]
    end
    @@users[username] = self.new(username)
    @@users[username]
  end

  attr_reader :username, :mask
  attr_writer :mask

  private
  def initialize (username)
    @username = username
  end
end
