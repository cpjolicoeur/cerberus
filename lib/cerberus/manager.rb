require 'fileutils'

require 'cerberus/utils'
require 'cerberus/constants'
require 'cerberus/config'
require 'cerberus/latch'
require 'cerberus/component_lazy_loader'

module Cerberus
  class AddCommand
    EXAMPLE_CONFIG = File.expand_path(File.dirname(__FILE__) + '/config.example.yml')
    
    def initialize(path, cli_options = {})
      @path, @cli_options = path, HashWithIndifferentAccess.new(cli_options)
    end
    
    def run
      scm_type = @cli_options[:scm] || Cerberus::SCM.guess_type(@path) || 'svn'
      scm = Cerberus::SCM.get(scm_type).new(@path, Config.new(nil, @cli_options))
      say "Can't find any #{scm_type} application under #{@path}" unless scm.url
      
      application_name = @cli_options[:application_name] || extract_project_name(@path)
      
      create_example_config
      
      config_name = "#{HOME}/config/#{application_name}.yml"
      say "Application #{application_name} already present in Cerberus" if File.exists?(config_name)
      
      app_config = { 'scm' => {
          'url' => scm.url,
          'type' =>  scm_type },
          'publisher' => {'mail' => {'recipients' => @cli_options[:recipients]}}
      }
      app_config['builder'] = {'type' => @cli_options[:builder]} if @cli_options[:builder]
      dump_yml(config_name, app_config)
      puts "Application '#{application_name}' has been added to Cerberus successfully" unless @cli_options[:quiet]
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
  
  class RemoveCommand
    # DRY: this is ugly and needs refactoring. It duplicates functionality from other 
    # classes a lot.
    
    def initialize(application_name, cli_options = {})
      unless File.exists?("#{HOME}/config/#{application_name}.yml")
        say "Project '#{application_name}' does not present in Cerberus. Type 'cerberus list' to see the list of all active projects."
      end
      @app_root = "#{HOME}/work/#{application_name}"
      
      def_options = {:application_root => @app_root, :application_name => application_name}
      @config = Config.new(application_name, cli_options.merge(def_options))
    end
    
    def run
      application_name = @config[:application_name]
      
      config_name = "#{HOME}/config/#{application_name}.yml"
      
      if not File.exists?(config_name)
        say "Unknown application #{application_name}"
        exit(1) 
      end
      FileUtils.rm_r @config[:application_root]
      File.unlink config_name
      puts "Application '#{application_name}' removed." unless @config[:quiet]
    end
  end
  
  class BuildCommand
    attr_reader :builder, :success, :scm, :status
    
    DEFAULT_CONFIG = {:scm => {:type => 'svn'}, 
      :log => {:enable => true}
    }
    
    def initialize(application_name, cli_options = {})
      unless File.exists?("#{HOME}/config/#{application_name}.yml")
        say "Project '#{application_name}' does not present in Cerberus. Type 'cerberus list' to see the list of all active projects."
      end
      
      app_root = "#{HOME}/work/#{application_name}"
      
      def_options = {:application_root => app_root + '/sources', :application_name => application_name} #pseudo options that stored in config. Could not be set in any config file not through CLI
      @config = Config.new(application_name, cli_options.merge(def_options))
      @config.merge!(DEFAULT_CONFIG, false)
      
      @status = Status.read("#{app_root}/status.log")
      
      scm_type = @config[:scm, :type]
      @scm = SCM.get(scm_type).new(@config[:application_root], @config)
      say "Client for SCM '#{scm_type}' does not installed" unless @scm.installed?
      
      builder_type = get_configuration_option(@config[:builder], :type, :rake)
      @builder = Builder.get(builder_type).new(@config)
    end
    
    def run
      begin
        Latch.lock("#{HOME}/work/#{@config[:application_name]}/.lock", :lock_ttl => 2 * LOCK_WAIT) do
          @scm.update!
          
          if @scm.has_changes? or @config[:force] or @status.previous_build_successful.nil?
            build_successful = @builder.run
            @status.keep(build_successful, @scm.current_revision, @builder.brokeness)
            
            #Save logs to directory
            if @config[:log, :enable]
              log_dir = "#{HOME}/work/#{@config[:application_name]}/logs/"
              FileUtils.mkpath(log_dir)
              
              time = Time.now.strftime("%Y%m%d%H%M%S")
              file_name = "#{log_dir}/#{time}-#{@status.current_state.to_s}.log"
              body = [ scm.last_commit_message, builder.output ].join("\n\n")
              IO.write(file_name, body)
            end
            
            #send notifications
            active_publishers = get_configuration_option(@config[:publisher], :active, 'mail')
            active_publishers.split(/\W+/).each do |pub|
              
              publisher_config = @config[:publisher, pub]
              raise "Publisher have no configuration: #{pub}" unless publisher_config
              
              events = interpret_state(publisher_config[:on_event] || @config[:publisher, :on_event] || 'default')
              Publisher.get(pub).publish(@status, self, @config) if events.include?(@status.current_state)
            end
            
            
            #Process hooks
            hooks = @config[:hook]
            hooks.each_pair{|name, hook|
              events = interpret_state(hook[:on_event] || 'all', false)
              if events.include?(@status.current_state)
                `#{hook[:action]}`
              end
            } if hooks
          end
          
        end #lock
      rescue Exception => e
        if ENV['CERBERUS_ENV'] == 'TEST'
          raise e
        else
          File.open("#{HOME}/error.log", File::WRONLY|File::APPEND|File::CREAT) do |f| 
            f.puts Time.now.strftime("%a, %d %b %Y %H:%M:%S [#{@config[:application_name]}] --  #{e.class}")
            f.puts e.message unless e.message.empty?
            f.puts e.backtrace.collect{|line| ' '*5 + line}
            f.puts "\n"
          end
        end
      end
    end
    
    private
    def get_configuration_option(hash, defining_key = nil, default_option = nil)
      if hash
        return hash[defining_key] if hash[defining_key]
        return hash.keys[0] if hash.size == 1
      end
      return default_option
    end
  end
  
  class BuildAllCommand
    def initialize(cli_options = {})
      @cli_options = cli_options
    end
    
    def run
      threads = []
      Dir["#{HOME}/config/*.yml"].each do |fn|
        fn =~ %r{#{HOME}/config/(.*).yml}
        application_name = $1
        
        command = Cerberus::BuildCommand.new(application_name, @cli_options)
        threads << Thread.new { command.run }
      end
      
      @already_waited = false
      threads.each do |t| 
        if @already_waited or not t.join(LOCK_WAIT)
          t.kill
          @already_waited = true
        end
      end
    end
  end
  
  class ListCommand
    def initialize(cli_options = {})                                                                             
    end
    
    def run
      projects = Dir["#{HOME}/config/*.yml"]
      if projects.empty?
        puts "There are no any active projects" 
      else
        puts "List of active projects:"
        
        projects.each do |fn|
          fn =~ %r{#{HOME}/config/(.*).yml}
          
          puts "  * #{$1}"
        end
        
        puts "\nType 'cerberus build PROJECT_NAME' to build any of these projects"
      end
    end
  end
  
  #Fields that are contained in status file
  # successful (true mean previous build was successful, otherwise - false)
  # timestamp
  # revision
  # brokeness
  # successful_build_timestamp
  # successful_build_revision
  class Status
    attr_reader :previous_build_successful, :previous_brokeness, :current_build_successful, :current_brokeness
    
    def initialize(param)
      if param.is_a? Hash
        @hash = param
        @current_build_successful = @hash['state']
        @already_kept = true
      else
        @path = param
        value = File.exists?(@path) ? YAML.load(IO.read(@path)) : nil
        
        @hash =
        case value
        when String
          value = %w(succesful successful setup).include?(value) #fix typo in status values
          {'successful' => value}
        when nil
          {}
        else
          value
        end
        
        @already_kept = false
      end
      
      @previous_build_successful = @hash['successful']
      @previous_brokeness = @hash['brokeness']
    end
    
    def self.read(file_name)
      Status.new(file_name)
    end
    
    def keep(build_successful, revision, brokeness)
      raise 'Status could be kept only once. Please try to reread status file.' if @already_kept
      
      @current_brokeness = brokeness
      @current_build_successful = build_successful
      
      hash = {'successful' => @current_build_successful, 'timestamp' => Time.now, 'revision' => revision, 'brokeness' => brokeness}
      if build_successful
        hash['successful_build_timestamp'] = Time.now
        hash['successful_build_revision'] = revision
      else
        hash['successful_build_timestamp'] = @hash['successful_build_timestamp']
        hash['successful_build_revision'] = @hash['successful_build_revision']
      end
      
      File.open(@path, "w+", 0777) { |file| file.write(YAML.dump(hash)) }
      
      @already_kept = true
    end
    
    def current_state
      raise "Invalid project state. Before calculating status please do keeping of it." unless @already_kept
      
      if @current_build_successful
        if @previous_build_successful.nil?
          :setup
        else
          @previous_build_successful ? :successful : :revival
        end
      else
        @previous_build_successful ? :failed : :broken
      end
    end
  end
end