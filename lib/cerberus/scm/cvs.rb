class Cerberus::SCM::CVS
  def initialize(path, config = {})
    raise "Path can't be nil" unless path

    @path, @config = path.strip, config
    @encoded_path = (@path.include?(' ') ? "\"#{@path}\"" : @path)
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
  def execute(command, parameters = nil, pre_parameters = nil)
    `#{@config[:bin_path]}cvs #{command} #{pre_parameters} #{@encoded_path} #{parameters}`
  end
end