$:.unshift("lib")
require 'chain'
require 'bitcoin'
require 'ffi'
require 'byebug'

require 'bundler/setup'
Bundler.require :default, :test

Bitcoin.network = :testnet3

Fixtures = JSON.parse(File.read("./spec/data.json"))

RSpec.configure do |config|
  config.order = 'random'
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
