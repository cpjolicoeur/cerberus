require 'cerberus/builder/ruby_base'

class Cerberus::Builder::Rake < Cerberus::Builder::RubyBase
  def initialize(config)
    super(config, "rake")
  end

  def successful?
    $?.exitstatus == 0 and not @output.include?("#{@cmd} aborted!")
  end
end
