class Cerberus::SCM::SVN
  def initialize(path, config = {})
    raise "Path can't be nil" unless path

    @path, @config = path.strip, config
    @encoded_path = (@path.include?(' ') ? "\"#{@path}\"" : @path)

    if test(?d, @path + '/.svn') #check first that it was not locked 
      execute("cleanup") if locked?
      FileUtils.rm_rf @path if locked? #In case if we could not unlock from command line - remove this directory at all
    end
  end

  def update!
    if test(?d, @path + '/.svn')
      @status = execute("update")
    else
      FileUtils.mkpath(@path) unless test(?d,@path)
      @status = execute("checkout", nil, @config[:scm, :url])
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
    message = execute("log", "--limit 1 -v")
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
  def locked?
    execute("st") =~ /^..L/
  end

  def info
    @info ||= YAML.load(execute("info"))
  end
    
  def execute(command, parameters = nil, pre_parameters = nil)
    `#{@config[:bin_path]}svn #{command} #{pre_parameters} #{@encoded_path} #{parameters}`
  end
end