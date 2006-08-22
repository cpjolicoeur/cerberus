class Cerberus::Builder::Maven2
  attr_reader :output

  def initialize(config)
    @config = config
  end

  def run
    Dir.chdir @config[:application_root]
    cmd = @config[:builder, :maven2, :cmd] || 'mvn'
    task = @config[:builder, :maven2, :task] || 'test'
    @output = `#{@config[:bin_path]}#{cmd} #{task} 2>&1`
    successful?
  end

  def successful?
    $?.exitstatus == 0 and not @output.include?('[ERROR] BUILD FAILURE')
  end
end