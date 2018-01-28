$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
$:.unshift File.expand_path(File.dirname(__FILE__))

gem "test-unit"
require 'test/unit'
require 'fileutils'

require 'cerberus/utils'
require 'mock/manager'

class Test::Unit::TestCase
  TEMP_DIR = File.expand_path(File.dirname(__FILE__)) + '/__workdir'
  HOME = TEMP_DIR + '/home'
  ENV['CERBERUS_HOME'] = HOME
  ENV['CERBERUS_ENV'] = 'TEST'

  SVN_REPO = TEMP_DIR + '/svn_repo'
  SVN_URL = 'file:///' + SVN_REPO.gsub(/\\/, '/').gsub(/^\//, '').gsub(' ', '%20')

  DARCS_REPO = TEMP_DIR + '/darcs_repo'
  DARCS_URL = 'file:///' + DARCS_REPO.gsub(/\\/, '/').gsub(/^\//, '').gsub(' ', '%20')

  GIT_REPO = TEMP_DIR + '/git_repo'
  GIT_URL = 'file:///' + GIT_REPO.gsub(/\\/, '/').gsub(/^\//, '').gsub(' ', '%20')

  HG_REPO = TEMP_DIR + '/hg_repo'
  HG_URL = 'file:///' + HG_REPO.gsub(/\\/, '/').gsub(/^\//, '').gsub(' ', '%20')

  def self.refresh_repos
    # setup base subversion repos
    FileUtils.rm_rf TEMP_DIR
    FileUtils.mkpath SVN_REPO
    `svnadmin create "#{SVN_REPO}"`
    `svnadmin load "#{SVN_REPO}" < "#{File.dirname(__FILE__)}/data/subversion.dump"`

    # setup base darcs repos
    require 'rubygems'
    require 'zip'
    FileUtils.mkpath DARCS_REPO
    Zip::File::open("#{File.dirname(__FILE__)}/data/darcs.zip") { |zf|
      zf.each { |e|
        fpath = File.join(DARCS_REPO, e.name)
        FileUtils.mkdir_p(File.dirname(fpath))
        zf.extract(e, fpath)
      }
    }

    # setup base git repos
    FileUtils.mkpath GIT_REPO
    Zip::File::open("#{File.dirname(__FILE__)}/data/git.zip") { |zf|
      zf.each { |e|
        fpath = File.join(GIT_REPO, e.name)
        FileUtils.mkdir_p(File.dirname(fpath))
        zf.extract(e, fpath)
      }
    }

    # setup base hg repos
    FileUtils.mkpath HG_REPO
    Zip::File::open("#{File.dirname(__FILE__)}/data/mercurial.zip") { |zf|
      zf.each { |e|
        fpath = File.join(HG_REPO, e.name)
        FileUtils.mkdir_p(File.dirname(fpath))
        zf.extract(e, fpath)
      }
    }
  end

  refresh_repos

  CERBERUS_PATH = File.expand_path(File.dirname(__FILE__) + '/../')

  def run_cerb(args)
    `ruby -I"#{CERBERUS_PATH}/lib" "#{CERBERUS_PATH}/bin/cerberus" #{args} 2>&1`
  end

  def add_test_case_to_project(project_name, content)
    test_case_name = "#{HOME}/work/#{project_name}/sources/test/#{rand(10000)}_test.rb"
    File.open(test_case_name, 'w') { |f|
      f << "require 'test/unit'

class A#{rand(10000)}Test < Test::Unit::TestCase
  def test_ok
    #{content}
  end
end"
    }

    if block_given?
      yield
      FileUtils.rm test_case_name
    end
  end

  def add_application(app_name, url, options = {})
    opt = {'scm' => {'url' => url},
           'publisher' => {
      'mail' => {'recipients' => 'somebody@com.com', 'delivery_method' => 'test'},
    }}

    opt.deep_merge!(options)

    dump_yml(HOME + "/config/#{app_name}.yml", opt)

    FileUtils.rm_rf HOME + "/work/#{app_name}"
  end

  def add_config(options)
    dump_yml(HOME + "/config.yml", options)
  end

  # Overrides the method +method_name+ in +obj+ with the passed block
  def override_method(obj, method_name, &block)
    # Get the singleton class/eigenclass for 'obj'
    klass = class << obj; self; end

    # Undefine the old method (using 'send' since 'undef_method' is protected)
    klass.send(:undef_method, method_name)

    # Create the new method
    klass.send(:define_method, method_name, block)
  end

  def build_successful?(file_name)
    data = YAML.load(IO.read(file_name))
    assert_kind_of Hash, data
    data['successful']
  end

  def build_status(successful)
    DummyStatus.new('state' => successful)
  end
end

require 'cerberus/config'
