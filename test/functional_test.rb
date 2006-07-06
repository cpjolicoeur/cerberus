require 'fileutils'
require 'test/unit'
require 'yaml'

require 'test_helper'

require 'cerberus/cli'

class FunctionalTest < Test::Unit::TestCase
  def test_add
    assert !File.exists?(HOME + '/config/svn_repo.yml')

    add = Cerberus::Add.new("    #{SVN_URL}   ", :quiet => true)
    add.run

    assert File.exists?(HOME + '/config/svn_repo.yml')
    assert_equal SVN_URL, load_yml(HOME + '/config/svn_repo.yml')['url']

    assert File.exists?(HOME + '/config.yml')
  end

  def test_build
    add_application('myapp', SVN_URL)
    
    build = Cerberus::Build.new('myapp')
    build.run

    status_file = HOME + '/work/myapp/status.log'
    assert File.exists?(status_file)
    assert_equal 'succesful', IO.read(status_file)

    FileUtils.rm status_file
    build = Cerberus::Build.new('myapp')
    build.run
    assert File.exists?(status_file)


    #test configuration for mail
#    dump_yml(HOME + '/config.yml', {'mail' => {'delivery_method'=>'test'})

    #remove status file to run project again
    FileUtils.rm status_file
    add_test_case_to_project('myapp', 'assert false') { #if assertion failed
      build = Cerberus::Build.new('myapp', :quiet => true)
      build.run

      assert_equal 'failed', IO.read(status_file)
    }

    #remove status file to run project again
    FileUtils.rm status_file
    add_test_case_to_project('myapp', 'raise "Some exception here"') { #if we have exception
      build = Cerberus::Build.new('myapp', :quiet => true)
      build.run

      assert_equal 'failed', IO.read(status_file)
    }
  end

  def test_have_no_awkward_header
    add_application('myapp', SVN_URL)
    
    build = Cerberus::Build.new('myapp')
    build.run

    assert build.checkout.last_commit_message !~ /-rHEAD -v/
    assert_equal 0, build.checkout.last_commit_message.index('-' * 72)
  end
end