class Test::Unit::TestCase
  CERBERUS_PATH = File.dirname(__FILE__) + '/../'

  def run_cerb(params)
    `ruby -I#{CERBERUS_PATH}/lib #{CERBERUS_PATH}/bin/cerberus #{params}`
  end
end