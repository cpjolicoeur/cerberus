require File.expand_path(File.dirname(__FILE__) + "/../cerberus")
require 'yaml'

class CerberusTest < Test::Unit::TestCase
  CERBERUS_HOME = Tempfile.make_tmpname

  def test_add_project_from_fs
    add_project_with_validation(File.dirname(__FILE__) + '/..')
  end

  def test_add_project_from_url
    add_project_with_validation('svn://rubyforge.org//var/svn/cerberus')
  end

  def add_project_with_validation(path)
    Cerberus::Manager.add!(path, :interact => false, :cerberus_home => CERBERUS_HOME)

    assert test(?f, CERBERUS_HOME + '/projects/cerberus.yml')
    config = YAML.load(IO.read(CERBERUS_HOME + '/projects/cerberus.yml'))
    assert_match Regex.new('svn(.*)://(.*)rubyforge.org//var/svn/cerberus/'), config['url']
    assert !File.exists?(CERBERUS_HOME + '/work')
  end

  def test_command_line
    #check how well ask user and how CL arguments work
  end

  def test_run_project
    Cerberus::Manager.run!('test_project', :cerberus_dir => CERBERUS_HOME)
    assert File.exists?(CERBERUS_HOME + '/work/test_project')
    assert !File.exists?(CERBERUS_HOME + '/work/test_project/.lock')
    assert File.exists?(CERBERUS_HOME + '/work/test_project/logs')
    assert File.exists?(CERBERUS_HOME + '/work/test_project/sources')

    log_files = Dir[CERBERUS_HOME + '/work/test_project/logs']
    assert 1, log_files.size
    log_content = IO.read(log_files[0])  #read log file
    assert_match /sucess/i, log_content  #our tests never fail, right? ;)

    Cerberus::Manager.run!('test_project', :cerberus_dir => CERBERUS_HOME)
    assert 1, Dir[CERBERUS_HOME + '/work/test_project/logs'].size  #run Cerberus again. Number of log files should not change (it is just several secs from previous check)

#test failure, check mail
  end

  def test_logless_run_project
    Cerberus::Manager.run!('test_project', :cerberus_dir => CERBERUS_HOME, :create_log => false)
    assert File.exists?(CERBERUS_HOME + '/work/test_project/sources')
    assert Dir[CERBERUS_HOME + '/work/test_project/logs'].empty?
  end

  def setup
    FileUtils.rm_rf(CERBERUS_HOME)
  end

  def teardown
    FileUtils.rm_rf(CERBERUS_HOME)
  end
end
