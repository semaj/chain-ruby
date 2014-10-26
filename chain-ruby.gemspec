#encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)
require "chain/version"

Gem::Specification.new do |s|
  s.name          = "chain-ruby"
  s.email         = "ryan@chain.com"
  s.version       = Chain::VERSION
  s.description   = "The Official Ruby SDK for Chain's Bitcoin API"
  s.summary       = "The Official Ruby SDK for Chain's Bitcoin API"
  s.authors       = ["Ryan R. Smith", "Eric Rykwalder", "Oleg Andreev"]
  s.homepage      = "http://github.com/chain-engineering/chain-btcruby"
  s.rubyforge_project = "chain-ruby"
  s.license       = "MIT"

  s.files = []
  s.files << "readme.md"
  s.files << "chain.pem"
  s.files << Dir["{lib,spec}/**/*.rb"]
  s.test_files = s.files.select {|path| path =~ /^spec\/.*_spec.rb/}

  s.require_path  = "lib"

  # TODO: When btcruby is published, uncomment this and remove btcruby from Gemfile.
  # s.add_runtime_dependency 'btcruby', '0.1.0'
  s.add_runtime_dependency 'ffi', '~> 1.9', '>= 1.9.3'

  s.add_development_dependency 'rspec', '3.1.0'
  s.add_development_dependency 'byebug', '3.4.0'
end
