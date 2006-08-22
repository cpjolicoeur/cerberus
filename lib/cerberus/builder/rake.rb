class Cerberus::Builder::Rake
  include Cerberus::Utils
  attr_reader :output

  def initialize(config)
    @config = config
  end

  def run
    Dir.chdir @config[:application_root]
    @output = `#{@config[:bin_path]}#{choose_rake_exec()} #{@config[:builder, :rake, :task]} 2>&1`
    successful?
  end

  def successful?
    $?.exitstatus == 0 and not @output.include?('rake aborted!')
  end

  private
  def choose_rake_exec
    ext = ['']

    if os() == :windows 
      ext << '.bat' << '.cmd'
    end

    silence_stream(STDERR) {
      ext.each do |e|
        begin
          out = `#{@config[:bin_path]}rake#{e} --version`
          return "rake#{e}" if out =~ /rake/
        rescue
        end
      end
    }

    raise "Rake builder did not find. Make sure that such script exists and have executable permissions."
  end
end