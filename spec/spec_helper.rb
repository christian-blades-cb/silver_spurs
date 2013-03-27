require 'simplecov' and SimpleCov.start if ENV['COVERAGE']

require_relative '../lib/silver_spurs'
require 'rack/test'

SilverSpurs::App.environment = :test

