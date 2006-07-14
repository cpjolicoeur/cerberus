require 'test_helper'

require 'cerberus/cli'

#require 'mocks/notifier'

class FunctionalTest < Test::Unit::TestCase
  def setup
    FileUtils.rm_rf HOME
  end

  def teardown
    FileUtils.rm_rf HOME
  end

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
    assert_equal 1, ActionMailer::Base.deliveries.size #first email that project was setup

    status_file = HOME + '/work/myapp/status.log'
    assert File.exists?(status_file)
    assert_equal 'succesful', IO.read(status_file)

    FileUtils.rm status_file
    build = Cerberus::Build.new('myapp')
    build.run
    assert File.exists?(status_file)

    assert_equal 2, ActionMailer::Base.deliveries.size #first email that project was setup

    build = Cerberus::Build.new('myapp')
    build.run
    assert_equal 2, ActionMailer::Base.deliveries.size #Number of mails not changed


    #remove status file to run project again
    FileUtils.rm status_file
    add_test_case_to_project('myapp', 'assert false') { #if assertion failed
      build = Cerberus::Build.new('myapp')
      build.run

      assert_equal 'failed', IO.read(status_file)
    }
    assert_equal 3, ActionMailer::Base.deliveries.size #We should receive mail if project fails


    #remove status file to run project again
    FileUtils.rm status_file
    add_test_case_to_project('myapp', 'raise "Some exception here"') { #if we have exception
      build = Cerberus::Build.new('myapp')
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