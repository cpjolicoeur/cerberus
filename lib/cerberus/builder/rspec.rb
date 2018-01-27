require 'cerberus/builder/ruby_base'

class Cerberus::Builder::RSpec < Cerberus::Builder::RubyBase
  def initialize(config)
    super(config, "rspec", "spec")
  end

  def run
    @output = if @config[:builder, @name.to_sym, :task]
                `#{@config[:bin_path]}rake #{@config[:builder, @name.to_sym, :task]} 2>&1`
              else
                `#{@config[:bin_path]}rake #{choose_exec()} 2>&1`
              end
    successful?
  end

  def brokeness
    if @output =~ /\d+ examples, (\d+) failures?/
      $1.to_i
    end
  end

  def successful?
    $?.exitstatus == 0 and not @output.include?("#{@cmd} aborted!") and @output.include?("0 failures")
  end
end
