require 'cerberus/publisher/base'

class Cerberus::Publisher::IRC < Cerberus::Publisher::Base
  def self.publish(state, build, options)
    config = options[:publisher, :rss]
    subject,body = Cerberus::Publisher::Base.formatted_message(state, build, options)

    #save message to RSS file
  end
end
