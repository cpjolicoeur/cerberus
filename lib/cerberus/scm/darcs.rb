class Cerberus::SCM::Darcs
  def initialize(path, config = {})
    raise "Path can't be nil" unless path

    @path, @config = path.strip, config
    @encoded_path = (@path.include?(' ') ? "\"#{@path}\"" : @path)
  end

  def update!
    if test(?d, @path + '/_darcs')
      @status = execute('pull', '-v -a')
    else
      FileUtils.rm_rf(@path) if test(?d,@path)
      FileUtils.mkpath(File.basename(@path)) unless test(?d,File.basename(@path))

      encoded_url = (@config[:scm, :url].include?(' ') ? "\"#{@config[:scm, :url]}\"" : @config[:scm, :url])
      @status = execute("get", "--partial #{encoded_url}")
    end

    extract_last_commit_info
  end

  def has_changes?
    return false if @status =~ /No remote changes to pull in!/
    return true if @status =~ /We have the following new \(to them\) patches:/
    return true if @status =~ /Copying patch \d+ of \d+\.\.\. done!/
    return false
  end

  def current_revision
    @date
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
    cmd = "#{@config[:bin_path]}darcs #{command} #{parameters} --repodir=#{@encoded_path}"
    `#{cmd}`
  end

  def extract_last_commit_info
    xml_message = execute('changes', "--last 1 --xml-output")
    require 'rexml/document'
    xml = REXML::Document.new(xml_message)
    @author = xml.elements["changelog/patch/@author"].value
    @date = xml.elements["changelog/patch/@date"].value
    @message = xml.elements["changelog/patch/name"].get_text.value
  end
end