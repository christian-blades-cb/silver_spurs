# -*- encoding: utf-8 -*-
require File.expand_path('../lib/silver_spurs/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Christian Blades"]
  gem.email         = ["christian.blades@careerbuilder.com"]
  gem.description   = %q{This is a simple REST service to kick off bootstrap processes. It is intended for use in a VPC-type environment with limited access.}
  gem.summary       = %q{RESTful service to kick off chef bootstraps}
  gem.homepage      = "http://github.com/christian-blades-cb/silver_spurs"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "silver_spurs"
  gem.require_paths = ["lib"]
  gem.version       = SilverSpurs::VERSION

  gem.add_dependency 'sinatra', '>= 1.3.5'
  gem.add_dependency 'chef', '>= 10.18.2'
  gem.add_dependency 'rest-client', '~> 1.6.7'
  gem.add_dependency 'addressable', '~> 2.3.3'

  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'growl'
  gem.add_development_dependency 'rb-fsevent',  '~> 0.9'
  gem.add_development_dependency 'rack-test'

end
