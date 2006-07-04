$:.unshift File.dirname(__FILE__) + '/../lib'

class Test::Unit::TestCase
  TEMP_DIR = File.expand_path(File.dirname(__FILE__)) + '/__workdir'

  SVN_REPO = TEMP_DIR + '/svn_repo'
  SVN_URL = 'file:///' + SVN_REPO.gsub(/\\/,'/')

  HOME = TEMP_DIR + '/home'
  ENV['CERBERUS_HOME'] = HOME

  def self.refresh_subversion
    FileUtils.rm_rf TEMP_DIR
    FileUtils.mkpath SVN_REPO
    `svnadmin create "#{SVN_REPO}"`
    `svnadmin load "#{SVN_REPO}" < "#{File.dirname(__FILE__)}/data/application.dump"`
  end

  refresh_subversion

  def setup
    FileUtils.rm_rf HOME
  end

  def teardown
    FileUtils.rm_rf HOME
  end

  CERBERUS_PATH = File.expand_path(File.dirname(__FILE__) + '/../')
  def run_cerb(args)
    `ruby -I#{CERBERUS_PATH}/lib #{CERBERUS_PATH}/bin/cerberus #{args}`
  end

  def silence_stream(stream)
    old_stream = stream.dup
    stream.reopen(os == :windows ? 'NUL:' : '/dev/null')
    stream.sync = true
    yield
  ensure
    stream.reopen(old_stream)
  end
end