require 'action_mailer'
require 'cerberus/publisher/base'

class Cerberus::Publisher::Mail < Cerberus::Publisher::Base
  def self.publish(state, build, options)
    mail_opts = options[:publisher, :mail].dup
    raise "There is no recipients provided for mail publisher" unless mail_opts[:recipients]

    configure(mail_opts)
    ActionMailerPublisher.deliver_message(state, build, options)
  end

  private
  def self.configure(config)
    [:authentication, :delivery_method].each do |k|
      config[k] = config[k].to_sym if config[k]
    end

    ActionMailer::Base.delivery_method = config[:delivery_method] if config[:delivery_method]
    ActionMailer::Base.server_settings = config
  end

  class ActionMailerPublisher < ActionMailer::Base
    def message(state, build, options)
      @subject, @body = Cerberus::Publisher::Base.formatted_message(state, build, options)
      @recipients, @sent_on = options[:publisher, :mail, :recipients], Time.now
      @from = options[:publisher, :mail, :sender] || "'Cerberus' <cerberus@example.com>"
#      raise "Please specify recipient addresses for application '#{options[:application_name]}'" unless options[:recipients]
    end
  end
end