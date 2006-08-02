require 'cerberus/version'

module Cerberus
  module Publisher
    class Base
      def self.formatted_message(state, build, options)
        subject = 
        case state
        when :setup
          "Cerberus set up for project (##{build.scm.current_revision})"
        when :broken
          "Build still broken (##{build.scm.current_revision})"
        when :failure
          "Build broken by #{build.scm.last_author} (##{build.scm.current_revision})"
        when :revival
          "Build fixed by #{build.scm.last_author} (##{build.scm.current_revision})"
        else
          raise "Unknown build state #{state}"
        end

        subject = "[#{options[:application_name]}] #{subject}"
        generated_by = "--\nCerberus #{Cerberus::VERSION::STRING}, http://rubyforge.org/projects/cerberus"
        body = [ build.scm.last_commit_message, build.output, generated_by ].join("\n\n")

        return subject, body
      end
    end
  end
end