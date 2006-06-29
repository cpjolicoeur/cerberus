class Test::Unit::TestCase
  CERBERUS_PATH = File.dirname(__FILE__) + '/../'

  def run_cerb(args)
    ENV
    `ruby -I#{CERBERUS_PATH}/lib #{CERBERUS_PATH}/bin/cerberus #{args}`
  end
end