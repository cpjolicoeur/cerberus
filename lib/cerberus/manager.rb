require 'rubygems'
require 'fileutils'

require 'cerberus/utils'
require 'cerberus/constants'
require 'cerberus/config'

require 'cerberus/publisher/mail'
require 'cerberus/publisher/jabber'
require 'cerberus/publisher/irc'
require 'cerberus/scm/svn'

module Cerberus
  SCM_TYPES = {
    'svn' => Cerberus::SCM::SVN
  }

  PUBLISHER_TYPES = {
    'mail' => Cerberus::Publisher::Mail,
    'jabber' => Cerberus::Publisher::Jabber,
    'irc' => Cerberus::Publisher::IRC,
  }

  class AddCommand
    EXAMPLE_CONFIG = File.expand_path(File.dirname(__FILE__) + '/config.example.yml')
    include Cerberus::Utils

    def initialize(path, cli_options = {})
      @path, @config = path, Config.new(nil, cli_options)
    end

    def run
      scm_type = @config[:scm] || 'svn'
      say "SCM #{scm_type} not supported" unless SCM_TYPES[scm_type]

      scm = SCM_TYPES[scm_type].new(@path, @config)
      say "Can't find any #{scm_type} application under #{@path}" unless scm.url

      application_name = @config[:application_name] || extract_project_name(@path)

      create_example_config
      
      config_name = "#{HOME}/config/#{application_name}.yml"
      say "Application #{application_name} already present in Cerberus" if File.exists?(config_name)

      app_config = { 'scm' => {
          'url' => scm.url,
          'type' =>  scm_type },
          'publisher' => {'mail' => {'recipients' => @config[:recipients]}}
      }
      dump_yml(config_name, app_config)
      puts "Application '#{application_name}' was successfully added to Cerberus" unless @config[:quiet]
    end

    private
    def extract_project_name(path)
      path = File.expand_path(path) if test(?d, path)
      File.basename(path).strip
    end

    def create_example_config
      FileUtils.mkpath(HOME) unless test(?d, HOME)
      FileUtils.cp(EXAMPLE_CONFIG, CONFIG_FILE) unless test(?f, CONFIG_FILE)
    end
  end

  class BuildCommand
    include Cerberus::Utils
    attr_reader :output, :success, :scm, :status

    def initialize(application_name, cli_options = {})
      unless File.exists?("#{HOME}/config/#{application_name}.yml")
        say "Project #{application_name} does not present in Cerberus"
      end

      app_root = "#{HOME}/work/#{application_name}"
      
      def_options = {:application_root => app_root + '/sources', :application_name => application_name} #pseudo options that stored in config. Could not be set in any config file not through CLI
      @config = Config.new(application_name, cli_options.merge(def_options))

      @status = Status.new("#{app_root}/status.log")

      @scm = SCM_TYPES[@config[:scm, :type] || 'svn'].new(@config[:application_root], @config)
    end
 
    def run
      begin
        previous_status = @status.recall
        @scm.update!

        state = 
        if @scm.has_changes? or not previous_status
          if status = make
            @status.keep(:succesful)
            case previous_status
            when :failed
              :revival
            when :succesful
              :succesful
            when false
              :setup
            end
          else
            @status.keep(:failed)
            previous_status == :failed ? :broken : :failure
          end
        else
          :unchanged
        end

        if [:failure, :broken, :revival, :setup].include?(state)
          PUBLISHER_TYPES.each_pair do |key, clazz|
            unless @config[:publisher, key, :recipients].blank?
              clazz.notify(state, self, @config)
            end
          end
        end
      rescue Exception => e
        if ENV['CERBERUS_ENV'] == 'TEST'
          raise e
        else
          File.open("#{HOME}/work/#{@config[:application_name]}/error.log", File::WRONLY|File::APPEND|File::CREAT) do |f| 
            f.puts Time.now.strftime("%a, %d %b %Y %H:%M:%S  --  #{e.class}")
            f.puts e.message unless e.message.blank?
            f.puts e.backtrace.collect{|line| ' '*5 + line}
            f.puts "\n"
          end
        end
      end
    end
 
    private
      def make
        Dir.chdir @config[:application_root]
        @output = `#{@config[:bin_path]}#{choose_rake_exec()} #{@config[:builder, :rake, :task]} 2>&1`
        make_successful?
      end
      
      def make_successful?
         $?.exitstatus == 0 and not @output.include?('rake aborted!')
      end

      def choose_rake_exec
        ext = ['']

        if os() == :windows 
          ext << '.bat' << '.cmd'
        end

        ext.each{|e|
          begin
            out = `#{@config[:bin_path]}rake#{e} --version`
            return "rake#{e}" if out =~ /rake/
          rescue
          end
        }
      end
  end

  class BuildAllCommand
    def initialize(cli_options = {})
      @cli_options = cli_options
    end

    def run
      Dir["#{HOME}/config/*.yml"].each do |fn|
        fn =~ %r{#{HOME}/config/(.*).yml}
        application_name = $1

        command = Cerberus::BuildCommand.new(application_name, @cli_options)
        command.run
      end
    end
  end

  class Status
    def initialize(path)
      @path = path
    end
    
    def keep(status)
      File.open(@path, "w+", 0777) { |file| file.write(status.to_s) }
    end
    
    def recall
      value = File.exists?(@path) ? File.read(@path) : false
      value.blank? ? false : value.to_sym
    end
  end
end
