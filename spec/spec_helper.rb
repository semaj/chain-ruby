require 'bundler/setup'
Bundler.require :default, :test

require 'byebug'
require 'rspec'
if $0 =~ /_spec\.rb$/
  # Fixing this deprecation warning:
  #   Requiring `rspec/autorun` when running RSpec via the `rspec` command is deprecated.
  #   Called from .../chain-ruby/spec/spec_helper.rb:7:in `require'.
  # I still need rspec/autorun for Cmd+R running of individual specs in TextMate.
  require 'rspec/autorun'
end
require_relative '../lib/chain'

Fixtures = JSON.parse(File.read(File.expand_path(File.dirname(__FILE__)) + "/fixtures.json"))

RSpec.configure do |config|
  config.order = 'random'
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
