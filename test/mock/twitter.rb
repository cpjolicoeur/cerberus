require 'twitter'

class Twitter::Client
  @@statuses = []

  def status( _action, _value )
    return nil unless _value
    case _action
    when :post
      @@statuses << _value
    when :delete
      @@statuses.delete_at( _value )
    when :get
      @@statuses[_value]
    else
      raise "ArgumentError: unknown action"
    end
  end

  def self.statuses
    @@statuses
  end
end
