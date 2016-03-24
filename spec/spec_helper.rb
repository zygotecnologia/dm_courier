if ENV.fetch('CI', false)
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

if ENV.fetch('COVERAGE', false)
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_filter '/spec/'
    coverage_dir 'tmp/coverage'
  end
end

require 'rubygems'
require 'bundler/setup'
require 'webmock/rspec'
Bundler.require(:default)

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].sort.each { |file| require file }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

  config.example_status_persistence_file_path = 'tmp/rspec_examples.txt'
  config.order = :random

  config.raise_errors_for_deprecations!
  config.run_all_when_everything_filtered = true
end

WebMock.disable_net_connect!(allow_localhost: true)
