require 'net/http'
require 'net/https'
require 'json'
require 'thread'
require 'uri'

# A module that wraps the Chain SDK.
module Chain
  autoload :Sweeper, 'chain/sweeper'
  autoload :Signer, 'chain/signer'
  autoload :Client, 'chain/client'
  autoload :Conn, 'chain/conn'
  autoload :APIEnumerator, 'chain/api_enumerator'
  autoload :ChainError, 'chain/chain_error'

  GUEST_KEY = 'GUEST-TOKEN'
  CHAIN_URL = 'https://api.chain.com'

  # A collection of root certificates used by api.chain.com
  CHAIN_PEM = File.expand_path('../../chain.pem', __FILE__)

  # Prefixed in the path of HTTP requests.
  API_VERSION = 'v2'
  BLOCK_CHAIN = 'bitcoin'

  def self.default_client=(c)
    @default_client = c
  end

  def self.default_client
    @default_client ||= Client.new
  end

  def self.method_missing(sym, *args, &block)
    default_client.send(sym, *args, &block)
  end

  def self.url
    @url ||= begin
      URI(ENV['CHAIN_URL'] || CHAIN_URL).tap do |u|
        u.user ||= GUEST_KEY
      end
    end
  end

  def self.block_chain
    BLOCK_CHAIN
  end

end
