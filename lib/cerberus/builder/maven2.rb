class Cerberus::Builder::Maven2
  attr_reader :output

  def initialize(config)
    @config = config
  end

  def run
    Dir.chdir @config[:application_root]
    cmd = @config[:builder, :maven2, :cmd] || 'mvn'
    @output = `#{@config[:bin_path]}#{cmd} #{@config[:builder, :maven2, :task]} 2>&1`
    successful?
  end

  def successful?
    $?.exitstatus == 0 and not @output.include?('r[ERROR] BUILD FAILURE')
  end
end