require 'bundler/setup'
Bundler.require :default, :test

require 'byebug'
require 'rspec'
require 'rspec/autorun'
require_relative '../lib/chain'

Fixtures = JSON.parse(File.read(File.expand_path(File.dirname(__FILE__)) + "/fixtures.json"))

RSpec.configure do |config|
  config.order = 'random'
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
