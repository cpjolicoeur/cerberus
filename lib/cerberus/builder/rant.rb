require 'cerberus/builder/ruby_base'

class Cerberus::Builder::Rant < Cerberus::Builder::RubyBase
  def initialize(config)
    super(config, "rant")
  end
end
