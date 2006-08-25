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
    while str =~ /^(.|\n)*Running (.*)\n(.|\n)* <<< FAILURE!$/
      failed_class = $2
      output << $` << $&
      output << "\n" << IO.readlines("#{@config[:application_root]}/target/surefire-reports/#{failed_class}.txt")[4..-1].join   
      str = $'
    end
    output << str
  end
end