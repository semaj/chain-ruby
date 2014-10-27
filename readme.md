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

Chain.key_id = 'YOUR-API-KEY-ID'
Chain.key_secret = 'YOUR-API-KEY-SECRET'

Chain.get_address('17x23dNjXJLzGMev6R63uyRhMWP1VHawKc') #=> array of Chain::AddressStatus objects.
```


## Configuration for Rails

To configure your API Key ID and API Key Secret for use by Rails, 
create `config/initializers/chain.rb` and add the following:

```ruby
Chain.key_id = 'YOUR-API-KEY-ID'
Chain.key_secret = 'YOUR-API-KEY-SECRET'
```

Then use `Chain` to access Chain API like so:

```ruby
Chain.get_address('17x23dNjXJLzGMev6R63uyRhMWP1VHawKc') #=> array of Chain::AddressStatus objects.
```


## API Key

By default, chain-ruby uses Chain's guest API key. It's great for trying library out, 
but for continuous development and deployment you should get an individual API key and 
a corresponding secret by signing up at https://chain.com. 

Once you signed up you will be able to specify your key ID and the secret:

```ruby
Chain.key_id = 'YOUR-API-KEY-ID'
Chain.key_secret = 'YOUR-API-KEY-SECRET'
```


## Advanced Setup

If you need to configure multiple instances with different keys or Bitcoin networks (mainnet / testnet),
then instead of using `Chain` object directly, create your own `Chain::Client` instance:

```ruby
client = Chain::Client.new
client.key_id = 'YOUR-API-KEY-ID'
client.key_secret = 'YOUR-API-KEY-SECRET'
client.network = Chain::NETWORK_TESTNET

client.get_address('17x23dNjXJLzGMev6R63uyRhMWP1VHawKc')
```


## Documentation

The Chain API Documentation is available at [https://chain.com/docs/ruby](https://chain.com/docs/ruby)


## Publishing a Rubygem

Be sure to bump the version.

```bash
$ gem build chain-ruby.gemspec
$ gem push chain-ruby-VERSION.gem
```
