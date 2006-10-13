require 'cerberus/version'

module Cerberus
  module Publisher
    class Base
      def self.formatted_message(state, manager, options)
        subject = 
        case state
        when :setup
          "Cerberus set up for project (##{manager.scm.current_revision})"
        when :broken
          "Build still broken (##{manager.scm.current_revision})"
        when :failure
          "Build broken by #{manager.scm.last_author} (##{manager.scm.current_revision})"
        when :revival
          "Build fixed by #{manager.scm.last_author} (##{manager.scm.current_revision})"
        else
          raise "Unknown build state #{state}"
        end

        subject = "[#{options[:application_name]}] #{subject}"
        generated_by = "--\nCerberus #{Cerberus::VERSION::STRING}, http://cerberus.rubyforge.org/"
        body = [ manager.scm.last_commit_message, manager.builder.output, generated_by ].join("\n\n")

        return subject, body
      end
    end
  end
end