require 'rubygems'
gem 'activesupport'
gem 'actionpack'
gem 'actionmailer'
require 'action_mailer'
require 'cerberus/publisher/base'

if RUBY_VERSION =~ /1\.8\.\d/
  # This hack works only on 1.8.x
  require 'cerberus/publisher/netsmtp_tls_fix'
end

class Cerberus::Publisher::Mail < Cerberus::Publisher::Base
  def self.publish(state, manager, options)
    mail_opts = options[:publisher, :mail].dup
    raise "There is no recipients provided for mail publisher" unless mail_opts[:recipients]

    configure(mail_opts)
    ActionMailerPublisher.email(state, manager, options).deliver_now
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
    layout false

    def email(state, manager, options)
      subject, body = Cerberus::Publisher::Base.formatted_message(state, manager, options)
      from = options[:publisher, :mail, :sender] || 'cerberus@example.com'
      to = options[:publisher, :mail, :recipients]
      raise "Please specify recipient addresses for application '#{options[:application_name]}'" unless to
      mail(subject: subject, from: from, to: to, sent_on: Time.now, body: body)
    end
  end
end
