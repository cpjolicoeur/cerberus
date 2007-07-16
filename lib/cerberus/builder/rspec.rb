require 'cerberus/builder/ruby_base'

class Cerberus::Builder::RSpec < Cerberus::Builder::RubyBase
  def initialize(config)
    super(config, "rspec", "spec")
  end

  def brokeness
    if @output =~ /\d+ examples, (\d+) failures/
      $1.to_i
    end
  end
end
