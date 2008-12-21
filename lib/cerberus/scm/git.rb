require 'cerberus/utils'

class Cerberus::SCM::Git
  def initialize(path, config = {})
    raise "Path can't be nil" unless path

    @path, @config = path.strip, config
    @encoded_path = (@path.include?(' ') ? "\"#{@path}\"" : @path)
  end

  def installed?
    exec_successful? "#{@config[:bin_path]}git --version"
  end

  def update!
    if test(?d, @path + '/.git')
      @status = execute('pull', '-v')
    else
      FileUtils.rm_rf(@path) if test(?d,@path)

      encoded_url = (@config[:scm, :url].include?(' ') ? "\"#{@config[:scm, :url]}\"" : @config[:scm, :url])
      @status = execute("clone", "#{encoded_url} #{@path}")
    end

    extract_last_commit_info
  end

  def has_changes?
    return false if @status =~ /Already up-to-date./
    return true if @status =~ /Fast forward/
    return true if @status =~ /Initialized empty Git repository/
    return false
  end

  def current_revision
    @revision
  end

  def url
    @path
  end

  def last_commit_message
    @message
  end

  def last_author
    @author
  end

  def output
    @status
  end

  private
  def execute(command, parameters = nil, with_path = true)
    cmd = "#{@config[:bin_path]}git #{command} #{parameters}"
    `#{cmd}`
  end

  def extract_last_commit_info
    message = execute("--git-dir=#{@path}/.git show", "--pretty='format:%an(%ae)|%ai|%H|%s'")
    message = message.split("|")
    
    @author = message[0]
    @date = message[1]
    @revision = message[2]
    @message = message[3]
  end
end
