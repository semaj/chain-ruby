## chain-ruby

[![Build Status](https://travis-ci.org/chain-engineering/chain-ruby.svg?branch=txn-dest-map)](https://travis-ci.org/chain-engineering/chain-ruby)

Chain's official Ruby SDK.

## Install

```bash
$ gem install chain-ruby
```

```ruby
require 'chain'
```

## Gemfile

```
gem 'chain-ruby', '~> 2.0.0'
```

## Quick Start

```ruby
require 'chain'
Chain.get_address('17x23dNjXJLzGMev6R63uyRhMWP1VHawKc')
```

## Documentation

The Chain API Documentation is available at [https://chain.com/docs/ruby](https://chain.com/docs/ruby)

## Publishing a Rubygem

Be sure to bump the version.

```bash
$ gem build chain-ruby.gemspec
$ gem push chain-ruby-VERSION.gem
```
