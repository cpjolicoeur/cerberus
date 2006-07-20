require 'action_mailer'

module Cerberus
  module Notifier
    class Email
      def self.notify(state, build, options)
        Email.configure(options)
        ActionMailerNotifier.deliver_message(state, build, options)
      end

      private
      def self.configure(options)
        mail_config = options[:mail] || {}
        [:authentication, :delivery_method].each do |k|
          mail_config[k] = mail_config[k].to_sym if mail_config[k]
        end

        ActionMailer::Base.delivery_method = mail_config[:delivery_method] if mail_config[:delivery_method]
        ActionMailer::Base.server_settings = mail_config
      end

      class ActionMailerNotifier < ActionMailer::Base
        def message(state, build, options)
          subject = 
          case state
          when :setup
            "Cerberus set up for project (##{build.checkout.current_revision})"
          when :broken
            "Build still broken (##{build.checkout.current_revision})"
          when :failure
            "Build broken by #{build.checkout.last_author} (##{build.checkout.current_revision})"
          when :revival
            "Build fixed by #{build.checkout.last_author} (##{build.checkout.current_revision})"
          end

          @subject = "[#{options[:application_name]}] #{subject}"
          @body    = [ build.checkout.last_commit_message, build.output ].join("\n\n")

          @recipients, @sent_on = options[:recipients], Time.now

          @from = options[:sender] || "'Cerberus' <cerberus@example.com>"
          raise "Please specify recipient addresses for application '#{options[:application_name]}'" unless options[:recipients]
        end
      end
    end
  end
end