require 'cerberus/builder/ruby_base'

class Cerberus::Builder::Rake < Cerberus::Builder::RubyBase
  def initialize(config)
    super(config, "rake")
  end
end
