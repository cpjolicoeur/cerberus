require 'cerberus/publisher/campfire'

class Marshmallow
  @@counter = 0

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