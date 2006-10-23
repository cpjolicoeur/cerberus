require 'cerberus/publisher/base'

class Cerberus::Publisher::Campfire < Cerberus::Publisher::Base
  def self.publish(state, manager, options)
    url = options[:publisher, :campfire, :url]
    
    subject,body = Cerberus::Publisher::Base.formatted_message(state, manager, options)
    Marshmallow.say(url, subject)
    Marshmallow.paste(url, body)
  end
end
#I've changed standard url from /rooms/ to /room/ as better choise



# Marshmallow, the campfire chatbot
#
# You need to know one the following:
#  (a) the secret public URL, or
#  (b) an account/password for your room and the room number.
#
# Usage:
#   to login with a password:
#
#   bot = Marshmallow.new( :domain => 'mydomain', :ssl => true )
#   bot.login :method => :login,
#     :username  => "yourbot@email.com",
#     :password => "passw0rd",
#     :room     => "11234"
#   bot.say("So many ponies in here! I want one!")
#
#  to use the public url:
#
#    Marshmallow.domain = 'mydomain' 
#    bot = Marshmallow.new
#    bot.login( :url => 'aDxf3' )
#    bot.say "Ponies!!"
#    bot.paste "<script type='text/javascript'>\nalert('Ponies!')\n</script>"
#

class Marshmallow
  require 'net/https'
  require 'open-uri'
  require 'cgi'
  require 'yaml'
  
  def self.version
    "0.2.5"
  end

  attr_accessor :domain

  def self.say(to, what)
    connect(to) { |bot| bot.say(what) }
  end
  
  def self.paste(to, what)
    connect(to) { |bot| bot.paste(what) }
  end
  
  # https://david:stuff@37s.campfirenow.com/room/11234
  def self.connect(to)
    if to =~ %r{(http|https)://([^:]+):(.+)@([^.]+).campfirenow.com/room/(\d+)}
      protocol, username, password, domain, room = $1, $2, $3, $4, $5
    else
      raise "#{to} didn't match format, try something like https://david:stuff@37s.campfirenow.com/room/11234"
    end

    bot = new(:domain => domain, :ssl => (protocol == "https"))
    bot.login(:username => username, :password => password, :method => :login, :room => room)

    yield bot
  end

  def initialize(options={})
    @debug  = options[:debug]
    @domain = options[:domain] || @@domain
    @ssl    = options[:ssl]
  end
  
  def login(options)
    options = { :method => :url, :username => 'Marshmallow' }.merge(options)
    
    @req = Net::HTTP::new("#{@domain}.campfirenow.com", @ssl ? 443 : 80)  
    @req.use_ssl = @ssl
    @req.verify_mode = OpenSSL::SSL::VERIFY_NONE if @ssl
    headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
    
    case options[:method]
    when :url
      res = @req.post("/#{options[:url]}", "name=#{options[:username]}", headers)
      # parse our response headers for the room number.. magic!
      @room_id = res['location'].scan(/room\/(\d+)/).to_s
      puts res.body if @debug
        
    when :login        
      params = "email_address=#{CGI.escape(options[:username])}&password=#{CGI.escape(options[:password])}"
      puts params if @debug
      res = @req.post("/login/", params, headers)
      @room_id = options[:room]
      puts "Logging into room #{@room_id}" if @debug
      puts res.body if @debug
    end
        
    @headers = { 'Cookie' => res.response['set-cookie'] }
    res2 = @req.get(res['location'], @headers)
    puts res2.body if @debug

    # refresh our headers
    @headers = { 'Cookie' => res.response['set-cookie'] }
    @req.get("/room/#{@room_id}/") # join the room if necessary
    return @headers
  end
  
  def paste(message)
    say(message, true)
  end
  
  def say(message, paste=false)
    puts "Posting #{message}" if @debug
    res = @req.post("/room/#{@room_id}/speak", "#{'paste=true&' if paste}message=#{CGI.escape(message.to_s)}", @headers)
    puts res.body if @debug
  end
end
