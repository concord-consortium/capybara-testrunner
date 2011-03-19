spec = Gem::Specification.new do |spec|
  spec.name           = "sc-testdriver"
  spec.version        = "0.1.1"
  spec.platform       = Gem::Platform::RUBY
  spec.authors        = ["Scott Cytacki"]
  spec.email          = ["scytacki@concord.org"]
  spec.homepage       = "http://github.com/concord-consortium/capybara-testrunner"
  spec.summary        = "Run your SproutCore unit tests"
  spec.description    = "Runs your SproutCore unit tests in a web browser and records the results"

  spec.add_dependency "daemon_controller"
  spec.add_dependency "selenium-client"
  spec.add_dependency "capybara"
  
  spec.files          = `git ls-files`.split("\n")
  spec.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")

  spec.executables    = ["sc-testdriver"]
  
  # the defaults
  spec.bindir         = ["bin"]
  spec.require_paths  = ["lib"]
end
