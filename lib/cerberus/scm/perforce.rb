require 'cerberus/utils'

class Cerberus::SCM::Perforce
  CHANGES_LOG_REGEXP = /^Change (\d+) on (.*) by (.*)\n\n(.*)/m

  def initialize(path, config = {})
    @config = config
    @path = path.strip

    @p4_view = @config[:scm, :view]
    @client_name = Socket.gethostname + ":" + @path.gsub(' ', ':')
  end

  def installed?
    exec_successful? "#{@config[:bin_path]}p4 info"
  end

  def update!
    FileUtils.mkpath(@path) unless test(?d,@path)
    create_client

    @status = execute("sync")
  end

  def has_changes?
    !@status.include?('file(s) up-to-date.')
  end

  def url
    @view
  end

  attr_reader :current_revision
  attr_reader :last_author
  attr_reader :last_commit_message

  private
  def last_revision
    unless @calculated
      msg = execute("changes -m 1 -l")
      msg =~ CHANGES_LOG_REGEXP
      
      @current_revision = $1
      #date = $2
      @last_author = $3
      @last_commit_message = $4.strip

      @calculated = true
    end
  end

  def execute(command)
    `#{@config[:bin_path]}p4 #{p4_opts()} #{command} #{@p4_view} 2>&1`
  end

  def p4_opts
    user_opt = @config[:scm, :user_name].to_s.empty? ? "" : "-u #{@config[:scm, :user_name]}"
    password_opt = @config[:scm, :password].to_s.empty? ? "" : "-P #{@config[:scm, :password]}"
    client_opt = "-c #{@client_name}"
    "#{user_opt} #{password_opt} #{client_opt}"
  end

  def create_client
    IO.popen("p4 #{p4_opts} client -i", "w+") do |io|
      io.puts(client_spec)
      io.close_write
    end
  end

  def client_spec
    <<-EOF
Client: #{@client_name}
Owner: #{@config[:scm, :user_name]}
Host: #{Socket.gethostname}
Description: Cerberus client
Root: #{@path}
Options: noallwrite noclobber nocompress unlocked nomodtime normdir
LineEnd: local
View: #{@p4_view} //#{@client_name}/...
EOF
  end
end
