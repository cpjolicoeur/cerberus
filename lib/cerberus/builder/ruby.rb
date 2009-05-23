require 'cerberus/builder/ruby_base'

class Cerberus::Builder::Ruby < Cerberus::Builder::RubyBase
  def initialize(config)
    super(config, "ruby")
  end
  
  def run
    ENV['PATH'] = "#{@config[:builder, @name.to_sym, :ruby_path]}::#{ENV['PATH']}"
    super
  end
  
  def successful?
    if ( @config[:builder, @name.to_sym, :failure] and @config[:builder, @name.to_sym, :success] )
      $?.exitstatus == 0 and !@output.include?(@config[:builder, @name.to_sym, :failure]) and @output.include?(@config[:builder, @name.to_sym, :success])
    else
      super # use RubyBase default if custom :success and :failure not specified
    end
  end

  def brokeness
    if @config[:builder, @name.to_sym, :brokeness]
      re = Regexp.new( @config[:builder, @name.to_sym, :brokeness] )
      md = re.match( @output )
      if md
        return md.captures.inject( 0 ) { |sum, n| sum += n.to_i }
      end
    else 
      super # use RubyBase default if custom :brokeness not specified
    end
  end
  
end
