require File.expand_path(File.dirname(__FILE__) + "/../cerberus")
require 'yaml'
require 'test/unit'
require 'tempfile'
require 'fileutils'

class CerberusTest < Test::Unit::TestCase
  CERBERUS_HOME = Dir::tmpdir + '/cerberus' + rand(10000).to_s

  def test_add_project_from_fs
    add_project_with_validation(File.dirname(__FILE__) + '/..')
  end

  def test_add_project_from_url
    add_project_with_validation('svn://rubyforge.org//var/svn/cerberus')
  end

  def add_project_with_validation(path)
    Cerberus::Manager.add!(path, :quiet => true, :cerberus_home => CERBERUS_HOME)

    assert test(?f, CERBERUS_HOME + '/config/cerberus.yml')
    config = YAML.load(IO.read(CERBERUS_HOME + '/config/cerberus.yml'))
    assert_match %r{svn.*://.*rubyforge\.org/var/svn/cerberus}, config['url']
    assert !File.exists?(CERBERUS_HOME + '/work')
  end

  def test_command_line
    #check how well ask user and how CL arguments work
  end

  def test_run_project
    add_config('test_project', {'url'=>'svn://rubyforge.org//var/svn/cerberus'})

    Cerberus::Manager.run!('test_project', :cerberus_home => CERBERUS_HOME)
    assert File.exists?(CERBERUS_HOME + '/work/test_project')
    assert !File.exists?(CERBERUS_HOME + '/work/test_project/.lock')
    assert File.exists?(CERBERUS_HOME + '/work/test_project/logs')
    assert File.exists?(CERBERUS_HOME + '/work/test_project/sources')

    log_files = Dir[CERBERUS_HOME + '/work/test_project/logs/*.log']
    assert 1, log_files.size
#    log_content = IO.read(log_files[0])  #read log file
#    assert_match /success/i, log_content  #our tests never fail, right? ;)

    Cerberus::Manager.run!('test_project', :cerberus_home => CERBERUS_HOME)
    assert 1, Dir[CERBERUS_HOME + '/work/test_project/logs/*.log'].size  #run Cerberus again. Number of log files should not change (it is just several secs from previous check)

#test failure, check mail
  end

  def test_logless_run_project
    add_config('test_project', {'url'=>'svn://rubyforge.org/var/svn/cerberus'})

    Cerberus::Manager.run!('test_project', :cerberus_home => CERBERUS_HOME, :skip_logs => true)
    assert File.exists?(CERBERUS_HOME + '/work/test_project/sources')
    assert Dir[CERBERUS_HOME + '/work/test_project/logs/*.log'].empty?
  end

  def setup
    FileUtils.rm_rf(CERBERUS_HOME)
  end

  def teardown
    FileUtils.rm_rf(CERBERUS_HOME)
  end

private
  def add_config(project_name, config)
    FileUtils.mkpath(CERBERUS_HOME + '/config')
    save_yaml(config, CERBERUS_HOME + "/config/#{project_name}.yml")
  end
end
