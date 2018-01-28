require 'twitter'

class Twitter::REST::Client
  @@statuses = []

  def update(_value)
    @@statuses << _value
  end

  def self.statuses
    @@statuses
  end
end
