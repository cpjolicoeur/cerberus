require 'cerberus/utils'

class Cerberus::SCM::CVS
  include Cerberus::Utils
  
  def initialize(path, config = {})
    raise "Path can't be nil" unless path

    @path, @config = path.strip, config
    @encoded_path = (@path.include?(' ') ? "\"#{@path}\"" : @path)
  end

  def installed?
    exec_successful? "#{@config[:bin_path]}cvs --version"
  end

  def update!
    if test(?d, @path + '/CVS')
      @status = execute("update")
    else
      FileUtils.mkpath(@path) unless test(?d,@path)
      @status = execute("checkout", nil, @config[:scm, :url])
    end
  end

  def has_changes?
    @status =~ /^[U|P|C] (.*)/
  end

  def current_revision
    raise NotImplementedError
  end

  def url
    raise NotImplementedError
  end

  def last_commit_message
    raise NotImplementedError
  end

  def last_author
    raise NotImplementedError
  end

  private
  def execute(command, parameters = nil, pre_parameters = nil)
    `#{@config[:bin_path]}cvs #{command} #{pre_parameters} #{@encoded_path} #{parameters}`
  end
end
