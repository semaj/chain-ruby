require 'btcruby'

require 'net/http'
require 'net/https'
require 'json'
require 'thread'
require 'uri'
require 'time'

require_relative 'chain/errors.rb'
require_relative 'chain/address_info.rb'
require_relative 'chain/client.rb'
require_relative 'chain/connection.rb'
require_relative 'chain/transaction.rb'

# A module that wraps the Chain SDK.
module Chain

  # Bitcoin mainnet network and blockchain (default)
  NETWORK_MAINNET = "bitcoin".freeze

  # Bitcoin testnet3 network and blockchain
  NETWORK_TESTNET = "testnet3".freeze

  # Base URL to access Chain.com.
  CHAIN_URL = 'https://api.chain.com'.freeze

  # Default key ID for trying out the library.
  # Note: since guest ID provides limited access, please sign up at Chain.com to acquire a personal key.
  GUEST_KEY_ID = 'GUEST-TOKEN'.freeze

  # Prefixed in the path of HTTP requests.
  API_VERSION = 'v1'.freeze

  # A collection of root certificates used by api.chain.com.
  CHAIN_PEM = File.expand_path('../../chain.pem', __FILE__)

  # Default base URL. You can override URL by setting CHAIN_URL.
  def self.default_url
    @default_url ||= URI(ENV['CHAIN_URL'] || CHAIN_URL)
  end

end

# Default client access via Chain module.
module Chain

  # Default client to which messages will be forwarded.
  def self.default_client=(c)
    @default_client = c
  end

  def self.default_client
    @default_client ||= Client.new(url: default_url, api_key_id: GUEST_KEY_ID)
  end

  def self.method_missing(sym, *args, &block)
    self.default_client.send(sym, *args, &block)
  end
end
