require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'

require "./lib/cerberus/version"

PKG_BUILD     = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
PKG_NAME      = 'cerberus'
PKG_VERSION   = Cerberus::VERSION::STRING + PKG_BUILD
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

RELEASE_NAME  = "REL #{PKG_VERSION}"

RUBYFORGE_PROJECT = "cerberus"
RUBYFORGE_USER    = "anatol"

task :default => [:test, :clean]

desc "Run the unit tests in test/unit"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = 'test/*_test.rb'
  t.verbose = true
end

desc "Clean all generated files"
task :clean => :clobber_package do
  rm_rf "#{File.dirname(__FILE__)}/test/__workdir"
  rm_rf "#{File.dirname(__FILE__)}/coverage"
  rm_rf "#{File.dirname(__FILE__)}/doc/site/output"
end


GEM_SPEC = Gem::Specification.new do |s|
  s.name = PKG_NAME
  s.version = PKG_VERSION
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = ">=1.8.2"

  s.summary = "Cerberus is a Continuous Integration tool that could be easily run from Cron."
  s.description = <<-DESC.strip.gsub(/\n\s+/, " ")
    Cerberus is a Continuous Integration software for Ruby projects. CI helps you keep your project
    in a good shape.

    For now Cerberus only work with projects that use Subversion but in the future it would be provided
    support for other VCS.

    Cerberus could be easily invoked from Cron (for Unix) or nnCron (for Windows) utilities.
  DESC

  s.add_dependency 'actionmailer', '>= 1.2.3'
  s.add_dependency 'rake', '>= 0.7.1'
  s.add_dependency 'jabber4r', '>= 0.8.0'
  s.add_dependency 'Ruby-IRC', '>= 1.0.3'

  s.files = Dir.glob("{bin,lib,test}/**/*").delete_if { |item| item.include?('__workdir') }
  s.files += %w(LICENSE README CHANGES Rakefile)
  s.files += Dir.glob("doc/*").delete_if { |item| item.include?('__workdir') }

  s.bindir = "bin"
  s.executables = ["cerberus"]
  s.default_executable = "cerberus"

  s.require_path = 'lib'

  s.has_rdoc = true
  s.extra_rdoc_files = [ "README" ]
  s.rdoc_options = [ "--main", "README" ]

  s.test_suite_file = "test/integration_test.rb"

  s.author = "Anatol Pomozov"
  s.email = "anatol.pomozov@gmail.com"
  s.homepage = "http://rubyforge.org/projects/cerberus"
  s.rubyforge_project = RUBYFORGE_PROJECT
end


Rake::GemPackageTask.new(GEM_SPEC) do |p|
  p.gem_spec = GEM_SPEC
  p.need_tar = true
  p.need_zip = true
end

task :install => [:clean, :test, :package] do
  system "gem install pkg/#{PKG_NAME}-#{PKG_VERSION}.gem"
end

task :uninstall => [:clean] do
  system "gem uninstall #{PKG_NAME}"
end

desc "Look for TODO and FIXME tags in the code"
task :todo do
  FileList.new(File.dirname(__FILE__)+'/**/*.rb').egrep(/#.*(FIXME|TODO|TBD|DEPRECATED)/i) 
end

task :reinstall => [:uninstall, :install]

task :site_webgen do
  sh %{pushd doc/site; webgen; scp -r output/* #{RUBYFORGE_USER}@rubyforge.org:/var/www/gforge-projects/#{RUBYFORGE_PROJECT}/; popd }
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.test_files = FileList['test/*_test.rb']
    t.output_dir = File.dirname(__FILE__) + "/coverage"
    t.verbose = true
  end
rescue Object
end

task :site_coverage => [:rcov] do
  sh %{ scp -r test/coverage/* #{RUBYFORGE_USER}@rubyforge.org:/var/www/gforge-projects/#{RUBYFORGE_PROJECT}/coverage/ }
end

task :release_files => [:clean, :package] do
  require 'meta_project'
  project = MetaProject::Project::XForge::RubyForge.new(RUBYFORGE_PROJECT)

  release_files = FileList[
    "pkg/#{PKG_FILE_NAME}.gem",
    "pkg/#{PKG_FILE_NAME}.zip",
    "pkg/#{PKG_FILE_NAME}.tgz"
  ]

  Rake::XForge::Release.new(project) do |release|
    release.user_name = RUBYFORGE_USER
    release.password = ENV['RUBYFORGE_PASSWORD']
    release.files = release_files.to_a
    release.package_name    = PKG_NAME
    release.release_name = "Cerberus #{PKG_VERSION}"
  end

end

task :publish_news do
  require 'meta_project'

  project = MetaProject::Project::XForge::RubyForge.new(RUBYFORGE_PROJECT)
  Rake::XForge::NewsPublisher.new(project) do |publisher|
    publisher.user_name = RUBYFORGE_USER
    publisher.password = ENV['RUBYFORGE_PASSWORD']
    publisher.subject = "[ANN] Cerberus #{PKG_VERSION} Released"
    publisher.details = IO.read(File.dirname(__FILE__) + '/README')
  end
end
