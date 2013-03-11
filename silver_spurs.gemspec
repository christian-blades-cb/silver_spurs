# -*- encoding: utf-8 -*-
require File.expand_path('../lib/silver_spurs/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Christian Blades"]
  gem.email         = ["christian.blades@careerbuilder.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = "http://github.com/christian-blades-cb"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "silver_spurs"
  gem.require_paths = ["lib"]
  gem.version       = SilverSpurs::VERSION

  gem.add_dependency 'sinatra', '>= 1.3.5'
  gem.add_dependency 'chef', '>= 10.18.2'

  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'growl'
  gem.add_development_dependency 'rb-fsevent',  '~> 0.9'
  gem.add_development_dependency 'rack-test'

end
