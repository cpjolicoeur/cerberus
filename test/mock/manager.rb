class DummyManager
  attr_reader :builder, :scm

  DummyScm = Struct.new(:last_commit_message, :current_revision, :last_author)
  DummyBuilder = Struct.new(:output)

  def initialize(last_commit_message, output, current_revision, last_author)
    @scm = DummyScm.new(last_commit_message, current_revision, last_author)
    @builder = DummyBuilder.new(output)
  end
end

class DummyStatus
  attr_reader :previous_brokeness, :current_brokeness

  def initialize(param)
    @hash = param
    @current_build_sucessful = @hash['state']
    @previous_build_successful = @hash['previous_build'] || false
    @previous_brokeness = @hash['previous_brokeness'] || ''
    @current_brokeness = @hash['current_brokeness'] || ''
  end

  def current_state
    if @current_build_successful
      if @previous_build_sucessful.nil?
        :setup
      else
        @previous_build_successful ? :successful : :revival
      end
    else
      @previous_build_successful ? :failed : :broken
    end
  end
end
