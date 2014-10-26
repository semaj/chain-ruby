require 'net/http'
require 'net/https'
require 'json'
require 'thread'
require 'uri'
require 'btcruby'
require 'ffi' # gem install ffi

require_relative 'chain/client.rb'
require_relative 'chain/connection.rb'

# A module that wraps the Chain SDK.
module Chain
  # Base URL to access Chain.com.
  CHAIN_URL = 'https://api.chain.com'

  # Default key ID for trying out the library.
  # Note: since guest ID provides limited access, please sign up at Chain.com to acquire a personal key.
  GUEST_KEY_ID = 'GUEST-TOKEN'

  # Prefixed in the path of HTTP requests.
  API_VERSION = 'v1'

  # A collection of root certificates used by api.chain.com.
  CHAIN_PEM = File.expand_path('../../chain.pem', __FILE__)

  # Raised when an unexpected error occurs in either
  # the HTTP request or the parsing of the response body.
  class ChainError < StandardError; end

  # Default base URL. You can override URL by setting CHAIN_URL.
  def self.default_url
    @default_url ||= URI(ENV['CHAIN_URL'] || CHAIN_URL)
  end

  # Chain.default_client allows accessing default client configuration via global Chain instance.
  def self.default_client=(c)
    @default_client = c
  end

  def self.default_client
    @default_client ||= Client.new(url: default_url, key_id: GUEST_KEY_ID)
  end

  def self.method_missing(sym, *args, &block)
    default_client.send(sym, *args, &block)
  end

end
