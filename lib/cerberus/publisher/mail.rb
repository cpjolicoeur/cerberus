require 'rubygems'
require 'action_mailer'
require 'cerberus/publisher/base'

if RUBY_VERSION > '1.8.2'
  #This hack works only on 1.8.4
  require 'cerberus/publisher/netsmtp_tls_fix'
end

class Cerberus::Publisher::Mail < Cerberus::Publisher::Base
  def self.publish(state, manager, options)
    mail_opts = options[:publisher, :mail].dup
    raise "There is no recipients provided for mail publisher" unless mail_opts[:recipients]

    configure(mail_opts)
    ActionMailerPublisher.deliver_message(state, manager, options)
  end

  private
  def self.configure(config)
    [:authentication, :delivery_method].each do |k|
      config[k] = config[k].to_sym if config[k]
    end

    ActionMailer::Base.delivery_method = config[:delivery_method] if config[:delivery_method]
    ActionMailer::Base.smtp_settings = config
  end

  class ActionMailerPublisher < ActionMailer::Base
    def message(state, manager, options)
      @subject, @body = Cerberus::Publisher::Base.formatted_message(state, manager, options)
      @recipients, @sent_on = options[:publisher, :mail, :recipients], Time.now
      @from = options[:publisher, :mail, :sender] || "'Cerberus' <cerberus@example.com>"
      raise "Please specify recipient addresses for application '#{options[:application_name]}'" unless @recipients
    end
  end
end