require 'cerberus/utils'
require 'cerberus/scm/base'

class Cerberus::SCM::Mercurial < Cerberus::SCM::Base
  def installed?
    exec_successful? "#{@config[:bin_path]}hg --version"
  end

  def update!
    @new = false
    if test(?d, File.join(@path, '.hg'))
      r = get_localrev
      get_updates
      r_new = get_localrev
      @has_changes = r_new != r
    else
      FileUtils.rm_rf(@path) if test(?d, @path)
      encoded_url = (@config[:scm, :url].include?(' ') ? "\"#{@config[:scm, :url]}\"" : @config[:scm, :url])
      @new = true
      @has_changes = true
      @status = execute("clone", "#{encoded_url} #{@path}", false)
      if branch = @config[:scm, :branch]
        execute('update', "-C #{branch}")
      end
    end
    extract_commit_info if @has_changes
  end

  def has_changes?
    @has_changes
  end

  def new?
    @new
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

  def output
    @status
  end

  private

  def get_localrev
    execute("id", '-i').strip
  end

  def get_updates
    execute("pull", '-u')
  end

  def remote_head
    branch = @config[:scm, :branch] || 'default'
  end

  def execute(command, parameters = nil, with_path = true)
    if with_path
      cmd = "cd #{@config[:application_root]} && #{@config[:bin_path]}hg #{command} #{parameters}"
    else
      cmd = "#{@config[:bin_path]}hg #{command} #{parameters}"
    end
    `#{cmd}`
  end

  def extract_commit_info(branch = 'default')
    message = execute("log", "-b #{branch} -r tip --template '{author}|{date|shortdate}|{node}|{desc}'").split("|")
    m = {:author => message.shift, :date => message.shift, :revision => message.shift, :message => message.shift}
    @message = m[:message]
    @author = m[:author]
    @date = m[:date]
    @revision = m[:revision]
    m
  end
end
