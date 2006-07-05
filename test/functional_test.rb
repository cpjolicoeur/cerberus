require 'fileutils'
require 'test/unit'
require 'yaml'

require 'test_helper'
require 'cerberus/cli'

class FunctionalTest < Test::Unit::TestCase
  def test_add
    assert !File.exists?(HOME + '/config/svn_repo.yml')

    Cerberus::Add.new("    #{SVN_URL}   ", :quiet => true)

    assert File.exists?(HOME + '/config/svn_repo.yml')
    assert_equal SVN_URL, YAML::load(IO.read(HOME + '/config/svn_repo.yml'))['url']

    assert File.exists?(HOME + '/config.yml')
  end

  def test_build
    Cerberus::Add.new(SVN_URL)
    
    build = Cerberus::Build.new('svn_repo')
    build.run

    status_file = HOME + '/work/svn_repo/status.log'
    assert File.exists?(status_file)
    assert_equal 'succesful', IO.read(status_file)

    FileUtils.rm status_file
    build = Cerberus::Build.new('svn_repo')
    build.run
    assert File.exists?(status_file)


    #test configuration for mail
    File.open(HOME + '/config.yml', 'w'){|f| YAML::dump({'mail' => {'delivery_method'=>'test'}}, f)}

    #remove status file to run project again
    FileUtils.rm status_file
    add_test_case_to_project('svn_repo', 'assert false') { #if assertion failed
      build = Cerberus::Build.new('svn_repo', :dry_run => true)
      build.run

      assert_equal 'failed', IO.read(status_file)
    }

    #remove status file to run project again
    FileUtils.rm status_file
    add_test_case_to_project('svn_repo', 'raise "Some exception here"') { #if we have exception
      build = Cerberus::Build.new('svn_repo', :dry_run => true)
      build.run

      assert_equal 'failed', IO.read(status_file)
    }
  end
end