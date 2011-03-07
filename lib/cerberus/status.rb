module Cerberus
  # Fields that are contained in status file
  #
  #   successful_build_timestamp
  #   timestamp
  #   successful (true mean previous build was successful, otherwise - false)
  #   revision
  #   brokeness
  #   successful_build_revision
  #
  class Status
    attr_reader :previous_build_successful, :previous_brokeness, :current_build_successful, :current_brokeness, :revision, :successful_build_revision
  
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
    
      @revision = @hash['revision']
      @successful_build_revision = @hash['successful_build_revision']
      @previous_build_successful = @hash['successful']
      @previous_brokeness = @hash['brokeness']

      # Create some convenience methods to access status
      @hash.keys.each { |key| self.class.send( :define_method, key ) { @hash[key] } }
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
  
    def previous_build_failed?
      # if @previous_build_successful.nil?
      #   return false
      # else
      #   ( :setup == current_state ) ? false : !@previous_build_successful
      # end
      @previous_build_successful.nil? ? false : !@previous_build_successful
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