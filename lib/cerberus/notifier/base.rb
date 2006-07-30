require 'action_mailer'

class Cerberus::Notifier::Base
  def self.formatted_message(state, build, options)
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
    else
      raise "Unknown build state #{state}"
    end

    subject = "[#{options[:application_name]}] #{subject}"
    body    = [ build.checkout.last_commit_message, build.output ].join("\n\n")

    return subject, body
  end
end