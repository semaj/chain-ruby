#encoding: UTF-8
Gem::Specification.new do |s|
  s.name          = "chain-ruby"
  s.email         = "ryan@chain.com"
  s.version       = "2.1.0pre2"
  s.description   = "The Official Ruby SDK for Chain's Bitcoin API"
  s.summary       = "The Official Ruby SDK for Chain's Bitcoin API"
  s.authors       = ["Ryan R. Smith", "Eric Rykwalder"]
  s.homepage      = "http://github.com/chain-engineering/chain-ruby"
  s.license       = "MIT"


  s.files = []
  s.files << "readme.md"
  s.files << "chain.pem"
  s.files << Dir["{lib,spec}/**/*.rb"]
  s.test_files = s.files.select {|path| path =~ /^spec\/.*_spec.rb/}

  s.require_path  = "lib"

  s.add_runtime_dependency 'chain-bitcoin-ruby', '0.0.1'

  s.add_development_dependency 'rspec', '3.1.0'
  s.add_development_dependency 'byebug', '3.4.0'
end
