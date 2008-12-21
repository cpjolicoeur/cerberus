require File.dirname(__FILE__) + '/test_helper'

require 'yaml'

class IntegrationTest < Test::Unit::TestCase
  def setup
    FileUtils.rm_rf HOME
  end

  def teardown
    FileUtils.rm_rf HOME
  end

  def test_add_project_as_url
    output = run_cerb("  add   #{SVN_URL}  ")
    assert_match /has been added to Cerberus successfully/, output
    assert File.exists?(HOME + '/config/svn_repo.yml')
    assert_equal SVN_URL, load_yml(HOME + '/config/svn_repo.yml')['scm']['url']

    #try to add second time
    output = run_cerb("add #{SVN_URL}")
    assert_match /already present/, output
    assert File.exists?(HOME + '/config/svn_repo.yml')
    assert_equal SVN_URL, load_yml(HOME + '/config/svn_repo.yml')['scm']['url']
  end

  def test_list_command
    run_cerb("  add   #{SVN_URL}  APPLICATION_NAME=mamba ")
    output = run_cerb('list')
    assert_match /mamba/, output
  end

  def test_add_project_with_parameters
    output = run_cerb("  add   #{SVN_URL}  APPLICATION_NAME=hello_world  RECIPIENTS=aa@gmail.com   BUILDER=maven2")
    assert_match /has been added to Cerberus successfully/, output

    assert File.exists?(HOME + '/config/hello_world.yml')
    cfg = load_yml(HOME + '/config/hello_world.yml')

    assert_equal 'svn', cfg['scm']['type']
    assert_equal SVN_URL, cfg['scm']['url']
    assert_equal 'aa@gmail.com', cfg['publisher']['mail']['recipients']
    assert_equal 'maven2', cfg['builder']['type']
  end

  def test_run_project
    add_application('svn_repo', SVN_URL, 'quiet' => true)

    run_cerb("build svn_repo")
    assert File.exists?(HOME + '/work/svn_repo/status.log')
    assert build_successful?(HOME + '/work/svn_repo/status.log')
  end

  def test_add_darcs_scm
    output = run_cerb("  add   #{DARCS_URL}  SCM=darcs")
    assert_match /has been added to Cerberus successfully/, output

    assert File.exists?(HOME + '/config/darcs_repo.yml')
    cfg = load_yml(HOME + '/config/darcs_repo.yml')

    assert_equal 'darcs', cfg['scm']['type']
    assert_equal DARCS_URL, cfg['scm']['url']
  end
  
  def test_add_git_scm
    output = run_cerb("  add   #{GIT_URL}  SCM=git")
    assert_match /has been added to Cerberus successfully/, output

    assert File.exists?(HOME + '/config/git_repo.yml')
    cfg = load_yml(HOME + '/config/git_repo.yml')

    assert_equal 'git', cfg['scm']['type']
    assert_equal GIT_URL, cfg['scm']['url']
  end

  def test_run_unexist_project
    output = run_cerb("build some_project")
    assert_match /Project 'some_project' does not present in Cerberus/, output
    assert !test(?d, HOME + '/work/some_project')
  end

  def test_add_cvs_explicit_scm
    output = run_cerb('add :pserver:webdev1:/home/cvs SCM=cvs APPLICATION_NAME=myapp RECIPIENTS=my.email@xxx.xx')
    assert_match /NotImplementedError/, output
#    assert_match /has been added to Cerberus successfully/, output
    
#    cfg = load_yml(HOME + '/config/darcs_repo.yml')
#    assert_equal 'cvs', cfg['scm']['type']
  end

  def test_add_cvs_implicit_scm
    output = run_cerb('add :pserver:webdev1:/home/cvs APPLICATION_NAME=myapp RECIPIENTS=my.email@xxx.xx')
    assert_match /NotImplementedError/, output
#    assert_match /has been added to Cerberus successfully/, output
    
#    cfg = load_yml(HOME + '/config/darcs_repo.yml')
#    assert_equal 'cvs', cfg['scm']['type']
  end

  def test_hook
    some_number = rand(100000)
    tmp_file = File.join(TEMP_DIR, 'some_number')
    config_file = HOME + '/config/hooks.yml'

    add_application('hooks', SVN_URL, 'quiet' => true)
    cfg = load_yml(config_file)

    cfg['hook'] = {'echo' => {'action' => "echo #{some_number} > #{tmp_file}"}}
    dump_yml(config_file, cfg)

    File.rm_f tmp_file
    run_cerb("build hooks")
    assert_equal some_number.to_s, IO.read(tmp_file).strip
    File.rm_f tmp_file
  end
end