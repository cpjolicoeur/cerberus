class Cerberus::Builder::Maven2
  attr_reader :output

  def initialize(config)
    @config = config
  end

  def run
    Dir.chdir @config[:application_root]
    cmd = @config[:builder, :maven2, :cmd] || 'mvn'
    task = @config[:builder, :maven2, :task] || 'test'
    output = `#{@config[:bin_path]}#{cmd} #{task} 2>&1`
    @output = add_error_information(output)
    successful?
  end

  def successful?
    $?.exitstatus == 0 and not @output.include?('[ERROR] BUILD FAILURE')
  end

  def add_error_information(str)
    output = ''
    while str =~ / <<< FAILURE!$/
      s = $'

      $` =~ /^(.|\n)*Running (.*)$/
      failed_class = $2
      output << $` << $& << ' <<< FAILURE!'
      output << "\n" << IO.readlines("#{@config[:application_root]}/target/surefire-reports/#{failed_class}.txt")[4..-1].map{|str| '  ' + str}.join.strip   #.gsub('  <<< FAILURE!','')
      str = s
    end
    output << str
  end
end