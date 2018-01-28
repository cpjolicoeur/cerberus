require 'cerberus/publisher/campfire'

class Marshmallow
  @@counter = 0

  class << self
    remove_method :say, :paste # We are about to overwrite method from Campfire
  end

  def self.say(to, what)
    @@counter += 1
  end

  def self.paste(to, what)
    @@counter += 1
  end

  def self.counter
    @@counter
  end
end
