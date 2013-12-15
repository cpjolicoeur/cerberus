require './lib/cerberus/constants'

Gem::Specification.new do |s|
  s.name = %q{cerberus}
  s.version = Cerberus::VERSION
  s.authors = ["Craig P Jolicoeur"]
  s.date = Time.now.utc.strftime("%Y-%m-%d")
  s.default_executable = %q{cerberus}
  s.executables = ["cerberus"]
  s.summary = %q{Cerberus is a Continuous Integration tool that could be easily run from Cron.}
  s.description = %q{Cerberus is a Continuous Integration software for Ruby projects. CI helps you keep your project in a good shape. Cerberus could be easily invoked from Cron (for Unix) or nnCron (for Windows) utilities.}
  s.email = %q{cpjolicoeur@gmail.com}
  s.license = %q{MIT}

  s.homepage = %q{http://rubyforge.org/projects/cerberus}
  s.require_paths = ["lib"]
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.2")
  s.rubygems_version = %q{1.3.7}
  s.rubyforge_project = %q{cerberus}

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files test`.split("\n")

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<actionmailer>, ["~> 2.0"])
      s.add_runtime_dependency(%q<activesupport>, ["~> 2.0"])
      s.add_runtime_dependency(%q<rake>, [">= 0.7.3"])
    else
      s.add_dependency(%q<actionmailer>, ["~> 2.0"])
      s.add_dependency(%q<activesupport>, ["~> 2.0"])
      s.add_dependency(%q<rake>, [">= 0.7.3"])
    end
  else
    s.add_dependency(%q<actionmailer>, ["~> 2.0"])
    s.add_dependency(%q<activesupport>, ["~> 2.0"])
    s.add_dependency(%q<rake>, [">= 0.7.3"])
  end

  # tests
  s.add_development_dependency 'rubyzip'
  s.add_development_dependency 'builder'
  s.add_development_dependency 'json'
end
