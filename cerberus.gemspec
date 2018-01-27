require './lib/cerberus/constants'

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY

  s.name = %q{cerberus}
  s.version = Cerberus::VERSION
  s.authors = ["Craig P Jolicoeur"]
  s.default_executable = %q{cerberus}
  s.homepage = %q{http://rubyforge.org/projects/cerberus}
  s.summary = %q{Cerberus is a Continuous Integration tool that could be easily run from Cron.}
  s.description = %q{Cerberus is a Continuous Integration software for Ruby projects. CI helps you keep your project in a good shape. Cerberus could be easily invoked from Cron (for Unix) or nnCron (for Windows) utilities.}
  s.email = %q{cpjolicoeur@gmail.com}
  s.license = %q{MIT}

  s.executables = ["cerberus"]
  s.require_path = "lib"
  s.rubyforge_project = %q{cerberus}

  s.files = Dir["CHANGELOG.md", "MIT-LICENSE", "README.rdoc", "lib/**/*"]

  s.add_dependency 'actionamailer'
  s.add_dependency 'activesupport'
  s.add_dependency 'rake'
  s.add_dependency 'xmpp4r'
  s.add_dependency 'shout-bot'
  s.add_dependency 'twitter'
  s.add_dependency 'addressable'

  # tests
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'power_assert'
  s.add_development_dependency 'rubyzip'
  s.add_development_dependency 'builder'
  s.add_development_dependency 'json'
  s.add_development_dependency 'webgen
end
