require 'fileutils'
require 'test/unit'
require 'yaml'

require 'test_helper'

class IntegrationTest < Test::Unit::TestCase
  def test_add_project_as_url
    output = run_cerb("  add   #{SVN_URL}  ")
    assert_match /was successfully added/, output
    assert File.exists?(HOME + '/config/svn_repo.yml')
    assert_equal SVN_URL, YAML::load(IO.read(HOME + '/config/svn_repo.yml'))['url']

    #try to add second time
    output = run_cerb("add #{SVN_URL}")
    assert_match /already present/, output
    assert File.exists?(HOME + '/config/svn_repo.yml')
    assert_equal SVN_URL, YAML::load(IO.read(HOME + '/config/svn_repo.yml'))['url']
  end

  def test_run_project
    output = run_cerb("   add    #{SVN_URL}    ")
    assert_match /was successfully added/, output
    assert File.exists?(HOME + '/config/svn_repo.yml')
    assert_equal SVN_URL, YAML::load(IO.read(HOME + '/config/svn_repo.yml'))['url']

    #FIXME why it does not working?
    run_cerb("build svn_repo")
    assert File.exists?(HOME + '/work/svn_repo/status.log')
    assert_equal 'succesful', IO.read(HOME + '/work/svn_repo/status.log')
  end
end