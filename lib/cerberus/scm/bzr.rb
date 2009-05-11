require 'cerberus/utils'
require 'time'

class Cerberus::SCM::Bazaar
  def initialize(path, config = {})
    raise "Path can't be nil" unless path

    @path, @config = path.strip, config
    @encoded_path = (@path.include?(' ') ? "\"#{@path}\"" : @path)
  end

  def installed?
    exec_successful? "#{@config[:bin_path]}bzr --version"
  end

  def update!
    if test(?d, @path + '/.bzr')
      extract_last_commit_info
      @status = execute("update", "2>&1")
    else
      FileUtils.rm_rf(@path) if test(?d, @path)
      @status = execute("checkout", nil, @config[:scm, :url])
    end
  end

  def has_changes?
    new_revision = @status.match(/^Updated to revision (\d+).$/)
    new_revision = new_revision[1] unless new_revision.nil?
    new_revision.to_i > current_revision
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

  private
  def execute(command, parameters = nil, pre_parameters = nil)
    `#{@config[:bin_path]}bzr #{command} #{pre_parameters} #{@encoded_path} #{parameters}`
  end

  def extract_last_commit_info
    lastlog = execute("log", "-r-1")
    # ------------------------------------------------------------
    # revno: 2222
    # committer: Paul Hinze <phinze@vpr0304>
    # branch nick: my-trunk
    # timestamp: Tue 2009-04-21 18:52:54 -0500
    # message:
    #   sidfugsdiufgsdifusdg
 
    @revision = lastlog.match(/^revno: (\d+)$/)[1].to_i
    @author   = lastlog.match(/^committer: (.+)$/)[1]
    @date     = Time.parse(lastlog.match(/^timestamp: (.+)$/)[1])
    @message  = lastlog.match(/message:\n  (.*)/m)[1]
  end
end
