$:.unshift File.dirname(__FILE__)

require 'fileutils'
require 'test/unit'

require 'test_helper'

class IntegrationTest < Test::Unit::TestCase
  TEMP_DIR = File.expand_path(File.dirname(__FILE__)) + '/__workdir'

  SVN_REPO = TEMP_DIR + '/svn_repo'
  SVN_URL = 'file:///' + SVN_REPO.gsub(/\\/,'/')

  HOME = TEMP_DIR + '/home'
  ENV['CERBERUS_HOME'] = HOME

  def self.refresh_subversion
    FileUtils.rm_rf TEMP_DIR
    FileUtils.mkpath SVN_REPO
    system("svnadmin create #{SVN_REPO}")
    system("svnadmin load #{SVN_REPO} < #{File.dirname(__FILE__)}/data/application.dump")
  end

  refresh_subversion

  def setup
    FileUtils.rm_rf HOME
  end

  def teardown
    FileUtils.rm_rf HOME
  end

  def test_add_project_as_url
    output = run_cerb("   add    #{SVN_URL}    ")
    assert_match /was successfully added/, output
    assert File.exists?(HOME + '/config/svn_repo.yml')

    #try to add second time
    output = run_cerb("add #{SVN_URL}")
    assert_match /already present/, output
    assert File.exists?(HOME + '/config/svn_repo.yml')
  end
end