require File.dirname(__FILE__) + '/test_helper'
require 'mock/marshmallow'
require 'cerberus/cli'

class FunctionalTest < Test::Unit::TestCase
  def setup
    FileUtils.rm_rf HOME
    ActionMailer::Base.deliveries.clear
  end

  def teardown
    Dir.chdir HOME + '/../' #We need change working directory to some non-removable dir otherwise we would have warning after removing that working directory absent
    FileUtils.rm_rf HOME
  end

  def test_add_by_url
    assert !File.exists?(HOME + '/config/svn_repo.yml')

    command = Cerberus::AddCommand.new("    #{SVN_URL}   ", :quiet => true)
    command.run

    assert File.exists?(HOME + '/config/svn_repo.yml')
    scm_conf = load_yml(HOME + '/config/svn_repo.yml')['scm']
    assert_equal 'svn', scm_conf['type']
    assert_equal SVN_URL, scm_conf['url']

    assert File.exists?(HOME + '/config.yml')
  end

  def test_add_by_dir
    sources_dir = File.dirname(__FILE__) + '/..'

    command = Cerberus::AddCommand.new(sources_dir, :quiet => true)
    command.run

    project_config = HOME + "/config/#{File.basename(File.expand_path(sources_dir))}.yml" #name of added application should be calculated from File System path

    assert File.exists?(project_config)
    scm_conf = load_yml(project_config)['scm']
    assert_equal 'svn', scm_conf['type']
    assert_match %r{svn(\+ssh)?://(\w+@)?rubyforge.org/var/svn/cerberus}, scm_conf['url']

    assert File.exists?(HOME + '/config.yml')
  end

  def test_build
    add_application('myapp', SVN_URL)

    build = Cerberus::BuildCommand.new('myapp', :changeset_url => 'http://someurl.changeset.com/')
    build.run
    assert_equal 1, ActionMailer::Base.deliveries.size #first email that project was setup
    mail = ActionMailer::Base.deliveries[0]
    output = mail.body

    #Check outpus that run needed tasks
    assert_match /1 tests, 1 assertions, 0 failures, 0 errors/, output
    assert output !~ /Task 'custom1' has been invoked/
    assert_equal '[myapp] Cerberus set up for project (#2)', mail.subject
    assert output =~ %r{http://someurl.changeset.com/2}

    status_file = HOME + '/work/myapp/status.log'
    assert File.exists?(status_file)
    assert_equal 'succesful', IO.read(status_file)
    assert 1, Dir[HOME + "/work/rake_cust/logs/*-succesful.log"].size

    FileUtils.rm status_file
    build = Cerberus::BuildCommand.new('myapp')
    build.run
    assert File.exists?(status_file)
    assert_equal 2, ActionMailer::Base.deliveries.size #first email that project was setup
    assert 2, Dir[HOME + "/work/rake_cust/logs/*.log"].size

    build = Cerberus::BuildCommand.new('myapp')
    build.run
    assert_equal 2, ActionMailer::Base.deliveries.size #Number of mails not changed
    assert 2, Dir[HOME + "/work/rake_cust/logs/*.log"].size #even if sources unchanged

    #remove status file to run project again
    FileUtils.rm status_file
    add_test_case_to_project('myapp', 'assert false') { #if assertion failed
      build = Cerberus::BuildCommand.new('myapp')
      build.run

      assert_equal 'failed', IO.read(status_file)
    }
    assert_equal 3, ActionMailer::Base.deliveries.size #We should receive mail if project fails


    #remove status file to run project again
    FileUtils.rm status_file
    add_test_case_to_project('myapp', 'raise "Some exception here"') { #if we have exception
      build = Cerberus::BuildCommand.new('myapp')
      build.run

      assert_equal 'failed', IO.read(status_file)
    }
  end

  def test_have_no_awkward_header
    add_application('myapp', SVN_URL, 'publisher' => {'active' => 'mail'})

    build = Cerberus::BuildCommand.new('myapp')
    build.run

    assert build.scm.last_commit_message !~ /-rHEAD -v/
    assert_equal 0, build.scm.last_commit_message.index('-' * 72)
  end

  def test_multiply_publishers_without_configuration
    add_application('myapp', SVN_URL, 'publisher' => {'active' => 'mail ,  jabber , irc,    dddd'})

    build = Cerberus::BuildCommand.new('myapp')

    begin
      build.run
    rescue RuntimeError => e
      assert_equal 'Publisher have no configuration: jabber', e.message
    else
      assert false
    end
  end

  def test_application_and_config_together
    add_config('publisher' => {'active' => 'jabber'})
    add_application('myapp', SVN_URL)
    build = Cerberus::BuildCommand.new('myapp')

    begin
      build.run
    rescue RuntimeError => e
      assert_equal 'Publisher have no configuration: jabber', e.message
    else
      assert false
    end
  end

  def test_batch_running
    add_application('myapp1', SVN_URL)
    add_application('myapp2', SVN_URL)
    add_application('myapp3', SVN_URL)
    add_application('myapp4', SVN_URL)

    build = Cerberus::BuildAllCommand.new
    build.run

    for i in 1..4 do
      status_file = HOME + "/work/myapp#{i}/status.log"
      assert File.exists?(status_file)
      assert_equal 'succesful', IO.read(status_file)
    end
  end

  def test_custom_task_for_rake
    add_application('rake_cust', SVN_URL, 'builder' => {'rake' => {'task' => 'custom1 custom2'}})
    build = Cerberus::BuildAllCommand.new
    build.run
    assert_equal 1, ActionMailer::Base.deliveries.size
    output = ActionMailer::Base.deliveries[0].body
    assert_match /Task 'custom1' has been invoked/, output
    assert_match /Task 'custom2' has been invoked/, output
  end

  def test_logs_disabled
    add_application('rake_cust', SVN_URL, 'log' => {'enable' => false})
    build = Cerberus::BuildAllCommand.new
    build.run

    assert !File.exists?(HOME + "/work/rake_cust/logs")
  end

  def test_darcs
    add_application('darcsapp', DARCS_URL, :scm => {:type => 'darcs'})

    build = Cerberus::BuildCommand.new('darcsapp')
    build.run
    assert build.scm.has_changes?
    assert_equal 1, ActionMailer::Base.deliveries.size #first email that project was setup
    mail = ActionMailer::Base.deliveries[0]
    output = mail.body

    #Check outpus that run needed tasks
    assert_match /1 tests, 1 assertions, 0 failures, 0 errors/, output
    assert output !~ /Task 'custom1' has been invoked/
    assert_equal '[darcsapp] Cerberus set up for project (#20061010090920)', mail.subject

    status_file = HOME + '/work/darcsapp/status.log'
    assert File.exists?(status_file)
    assert_equal 'succesful', IO.read(status_file)
    assert 1, Dir[HOME + "/work/darcsapp/logs/*.log"].size

    #There were no changes - no reaction should be
    build = Cerberus::BuildCommand.new('darcsapp')
    build.run
    assert_equal false, build.scm.has_changes?
    assert_equal 1, ActionMailer::Base.deliveries.size #first email that project was setup
    assert 1, Dir[HOME + "/work/darcsapp/logs/*.log"].size

    #now we add new broken test
    test_case_name = "test/#{rand(10000)}_test.rb"
    File.open(DARCS_REPO + '/' + test_case_name, 'w') { |f|
      f << "require 'test/unit'
        class A#{rand(10000)}Test < Test::Unit::TestCase
          def test_ok
            assert false
          end
        end"
    }

    curr_dir = Dir.pwd
    Dir.chdir DARCS_REPO
    `darcs add #{test_case_name}`
    `darcs record -a -A test@gmail.com -m somepatch`
    Dir.chdir curr_dir

    build = Cerberus::BuildCommand.new('darcsapp')
    build.run
    assert build.scm.has_changes?
    assert_equal 2, ActionMailer::Base.deliveries.size #first email that project was setup
    assert 2, Dir[HOME + "/work/darcsapp/logs/*.log"].size

    build = Cerberus::BuildCommand.new('darcsapp')
    build.run
    assert_equal false, build.scm.has_changes?
    assert_equal 2, ActionMailer::Base.deliveries.size #first email that project was setup
    assert 2, Dir[HOME + "/work/darcsapp/logs/*.log"].size

    #Now we broke remote repository (imiitate that network unaccessage)
    FileUtils.rm_rf DARCS_REPO
    build = Cerberus::BuildCommand.new('darcsapp')
    build.run
    assert_equal false, build.scm.has_changes?
  end

  def test_campfire_publisher
    #there were no any messages cause login/password is incorrect. We just check that there was no any exceptions
    add_application('campapp', SVN_URL, 'publisher' => {'active' => 'campfire', 'campfire' => 
      {'url' => 'http://mail@gmail.com:somepwd@cerberustool.campfirenow.com/room/5166022'}
    })

    build = Cerberus::BuildCommand.new('campapp')
    build.run

    assert_equal 2, Marshmallow.counter
  end
end