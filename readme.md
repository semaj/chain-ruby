## chain-ruby

[![Build Status](https://travis-ci.org/chain-engineering/chain-ruby.svg?branch=txn-dest-map)](https://travis-ci.org/chain-engineering/chain-ruby)

Chain's official Ruby SDK.

## Installation with RubyGems

The Chain gem is mirrored on RubyGems. To install it, run the following command:

```bash
$ gem install chain-ruby
```

If you use Bundler, simply add the following line to your Gemfile:

```ruby
gem 'chain-ruby', '~> 0.3.0'
```

## Quick Start

Once you have installed the gem, you can use the Chain module to interact with the Chain API.

```ruby
require 'chain'
         
client = Chain::Client.new(
           key_id: 'YOUR-API-KEY-ID', 
       key_secret: 'YOUR-API-KEY-SECRET')

client.get_address('17x23dNjXJLzGMev6R63uyRhMWP1VHawKc') #=> array of Chain::AddressStatus objects.
```


## Configuration for Rails

To configure your API Key ID and API Key Secret for use by Rails, create `config/initializers/chain.rb` and add the following:

```ruby
ChainClient = Chain::Client.new(key_id: 'YOUR-API-KEY-ID', 
                            key_secret: 'YOUR-API-KEY-SECRET')
```

Then use `ChainClient` to access Chain API like so:

```ruby
ChainClient.get_address('17x23dNjXJLzGMev6R63uyRhMWP1VHawKc') #=> array of Chain::AddressStatus objects.
```


## API Key

By default, chain-ruby uses Chain's guest API key. It's great for trying library out, but for continuous development and deployment you should get an individual API key and corresponding secret by signing up at https://chain.com. Once you signed up you will be able to specify your key ID and the secret:

```ruby
ChainClient = Chain::Client.new(key_id: 'YOUR-API-KEY-ID', 
                            key_secret: 'YOUR-API-KEY-SECRET')
```

## Documentation

The Chain API Documentation is available at [https://chain.com/docs/ruby](https://chain.com/docs/ruby)


## Publishing a Rubygem

Be sure to bump the version.

```bash
$ gem build chain-ruby.gemspec
$ gem push chain-ruby-VERSION.gem
```
