require 'rubygems'
Gem::manage_gems

Gem::Specification.new do |s|
  s.name = 'cerberus'
  s.version = '0.1'
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = ">=1.8.2"

  s.summary = "Cerberus is a simple Continuous Integration that could be easily run from Cron."

  s.add_dependency('actionmailer','>= 1.2.1')

  s.files = Dir.glob("{bin,doc,lib,test}/**/*").delete_if { |item| item.include?( ".svn" ) }
  s.files += %w(MIT-LICENSE README ChangeLog) #post-install.rb

  s.bindir = "bin"
  s.executables = ["cerberus"]
  s.default_executable = "cerberus"

  s.require_path = 'lib'

  s.has_rdoc = true
  s.extra_rdoc_files = [ "README" ]
  s.rdoc_options = [ "--main", "README" ]

  s.test_suite_file = "test/tests.rb"

  s.author = "Anatol pomozov"
  s.email = "anatol.pomozov@gmail.com"
#   s.homepage = "http://rubyforge.org/projects/cerberus"
  s.rubyforge_project = "cerberus"
end

if $0==__FILE__
  Gem::manage_gems
  Gem::Builder.new(spec).build
end