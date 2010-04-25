require 'tinder'
require 'cerberus/publisher/base'

class Cerberus::Publisher::Campfire < Cerberus::Publisher::Base
  def self.publish(state, manager, options)

    # TODO: parse out url into other fields if they don't exist for backwards compat
    url = options[:publisher, :campfire, :url]
    
    room      = options[:publisher, :campfire, :room]
    username  = options[:publisher, :campfire, :username]
    password  = options[:publisher, :campfire, :password] 
    subdomain = options[:publisher, :campfire, :subdomain]
    token     = options[:publisher, :campfire, :token]
    
    subject,body = Cerberus::Publisher::Base.formatted_message(state, manager, options)
    
    begin
      campfire = if token.nil?
        Tinder::Campfire.new( subdomain, :token => token )
      else
        Tinder::Campfire.new( subdomain, :username => username, :password => password)
      end
      
      puts "rooms: #{campfire.rooms.to_yaml}"
    
      room = campfire.find_room_by_name( name )
      room.speak( subject )
      room.paste( body )
    rescue Tinder::AuthenticationFailed
      say("Campfire authentication error. Please check your login credentials in your config file.")
    rescue Tinder::SSLRequiredError
      say("Campfire SSL error")
    end
  end
end