require 'cerberus/utils'
require 'cerberus/scm/base'
require 'time'

class Cerberus::SCM::Bazaar < Cerberus::SCM::Base

  def installed?
    exec_successful? "#{@config[:bin_path]}bzr --version"
  end

  def update!
    if test(?d, File.join(@path, '.bzr'))
      extract_last_commit_info
      @old_revision = @revision
      # Revert in an attempt to avoid conflicts from local file changes
      execute("revert", "--no-backup 2>&1")
      @status = execute("update", "2>&1")
    else
      @old_revision = 0
      FileUtils.rm_rf(@path) if test(?d, @path)
      @status = execute("checkout", nil, @config[:scm, :url])
    end
    extract_last_commit_info
  end

  def has_changes?
    @revision.to_i > @old_revision.to_i
  end

  def current_revision
    @revision
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
 
    @revision = lastlog.match(/^revno: (\d+).*$/)[1].to_i
    @author   = lastlog.match(/^committer: (.+)$/)[1]
    @date     = Time.parse(lastlog.match(/^timestamp: (.+)$/)[1])
    @message  = lastlog.match(/message:\n  (.*)/m)[1]
  end
end
