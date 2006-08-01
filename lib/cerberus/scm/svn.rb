class Cerberus::SCM::SVN
  def initialize(path, options = {})
    raise "Path can't be nil" unless path

    @path, @options = path.strip, options
    @encoded_path = (@path.include?(' ') ? "\"#{@path}\"" : @path)
  end

  def update!
    if test(?d, @path + '/.svn')
      execute("svn cleanup") #TODO check first that it was locked
      @status = execute("svn update")
    else
      FileUtils.mkpath(@path) unless test(?d,@path)
      @status = execute("svn checkout", nil, @options[:scm, :url])
    end
  end

  def has_changes?
    @status =~ /[A-Z]\s+[\w\/]+/
  end

  def current_revision
    info['Revision'].to_i
  end

  def url
    info['URL']
  end

  def last_commit_message
    message = execute("svn log", "--limit 1 -v")
    #strip first line that contains command line itself (svn log --limit ...)
    if ((idx = message.index('-'*72)) != 0 )
      message[idx..-1]
    else
      message
    end
  end

  def last_author
    info['Last Changed Author']
  end

  private
    def info
      @info ||= YAML.load(execute("svn info"))
    end
    
    def execute(command, parameters = nil, pre_parameters = nil)
      `#{@options[:bin_path]}#{command} #{pre_parameters} #{@encoded_path} #{parameters}`
    end
end