require 'cerberus/builder/base'

class Cerberus::Builder::Maven2
  attr_reader :output, :brokeness

  def initialize(config)
    @config = config
  end

  def run
    Dir.chdir @config[:application_root]
    cmd = @config[:builder, :maven2, :cmd] || 'mvn'
    task = @config[:builder, :maven2, :task] || 'test'
    @output = `#{@config[:bin_path]}#{cmd} #{settings} #{task} 2>&1`
    add_error_information
    successful?
  end

  def settings
    settings_file = @config[:builder, :maven2, :settings]
    if settings_file
      return "-s #{settings_file}"
    else
      return ''
    end
  end

  def successful?
    $?.exitstatus == 0 and not @output.include?('[ERROR] BUILD FAILURE')
  end

  def add_error_information
    str = @output
    @output = ''
    @brokeness = 0
    while str =~ / <<< FAILURE!$/
      @brokeness += 1
      s = $'

      $` =~ /^(.|\n)*Running (.*)$/
      failed_class = $2
      @output << $` << $& << ' <<< FAILURE!'
      surefire_report_filename = "#{@config[:application_root]}/target/surefire-reports/#{failed_class}.txt"
      @output << "\n" << IO.readlines(surefire_report_filename)[4..-1].join.lstrip if test(?e, surefire_report_filename)
      str = s
    end
    @output << str
  end
end
