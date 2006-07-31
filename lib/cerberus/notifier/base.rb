require 'cerberus/version'

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
    generated_by = "--\nCerberus #{Cerberus::VERSION::STRING}, http://rubyforge.org/projects/cerberus"
    body = [ build.checkout.last_commit_message, build.output, generated_by ].join("\n\n")

    return subject, body
  end
end