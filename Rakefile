#!/usr/bin/env rake
require "bundler/gem_tasks"
require "rspec/core/rake_task"

desc 'Run all tests'
task :test => [:spec]

desc "Run all rspec tests"
RSpec::Core::RakeTask.new 'spec' do |t|
  t.pattern = 'spec/**/*_spec.rb'
#  t.rspec_opts = '-I spec -I spec/lib/silver_spurs -I lib -I . -fd
  #  -c'
  t.rspec_opts = '-fd -c'
end

desc "Run all rspec tests and generate a coverage report"
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['spec'].invoke
  `open coverage/index.html` if RUBY_PLATFORM.downcase.include? 'darwin'
end
