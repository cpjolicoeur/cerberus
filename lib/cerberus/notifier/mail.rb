require 'action_mailer'
require 'cerberus/notifier/base'

class Cerberus::Notifier::Mail < Cerberus::Notifier::Base
  def self.notify(state, build, options)
    configure(options[:notifier, :mail].dup)
    ActionMailerNotifier.deliver_message(state, build, options)
  end

  private
  def self.configure(config)
    [:authentication, :delivery_method].each do |k|
      config[k] = config[k].to_sym if config[k]
    end

    ActionMailer::Base.delivery_method = config[:delivery_method] if config[:delivery_method]
    ActionMailer::Base.server_settings = config
  end

  class ActionMailerNotifier < ActionMailer::Base
    def message(state, build, options)
      @subject, @body = Cerberus::Notifier::Base.formatted_message(state, build, options)
      @recipients, @sent_on = options[:notifier, :email, :recipients], Time.now
      @from = options[:notifier, :email, :recipients] || "'Cerberus' <cerberus@example.com>"
#      raise "Please specify recipient addresses for application '#{options[:application_name]}'" unless options[:recipients]
    end
  end
end