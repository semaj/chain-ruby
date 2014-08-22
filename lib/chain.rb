require 'net/http'
require 'net/https'
require 'json'
require 'thread'
require 'uri'

# A module that wraps the Chain HTTP API.
module Chain
  autoload :Sweeper, 'chain/sweeper'

  @conn_mutex = Mutex.new

  GUEST_KEY = 'GUEST-TOKEN'
  API_URL = URI('https://api.chain.com')

  # A collection of root certificates used by api.chain.com
  CHAIN_PEM = File.expand_path('../../chain.pem', __FILE__)

  # Prefixed in the path of HTTP requests.
  API_VERSION = 'v1'
  BLOCK_CHAIN = 'bitcoin'

  # Raised when an unexpected error occurs in either
  # the HTTP request or the parsing of the response body.
  ChainError = Class.new(StandardError)

  # Provide a Bitcoin address.
  # Returns basic details for a Bitcoin address (hash).
  def self.get_address(address)
    get("/#{API_VERSION}/#{block_chain}/addresses/#{address}")
  end

  # Provide an array of Bitcoin addresses.
  # Returns an array of basic details for a set of Bitcoin address (hash).
  def self.get_addresses(addresses)
    self.get_address(addresses.join(','))
  end

  # Provide a Bitcoin address.
  # Returns unspent transaction outputs for a Bitcoin address (array of hashes).
  def self.get_address_unspents(address)
    get("/#{API_VERSION}/#{block_chain}/addresses/#{address}/unspents")
  end

  # Provide an array of Bitcoin addresses.
  # Returns an array of unspent transaction outputs
  # for a set of Bitcoin address (array of hashes).
  def self.get_addresses_unspents(addresses)
    self.get_address_unspents(addresses.join(','))
  end

  # Provide a Bitcoin address.
  # Returns transactions for a Bitcoin address (array of hashes).
  def self.get_address_transactions(address, options={})
    get("/#{API_VERSION}/#{block_chain}/addresses/#{address}/transactions",
      options)
  end

  # Provide an array of Bitcoin address.
  # Returns an array of transactions for a set of Bitcoin address
  # (array of hashes).
  def self.get_addresses_transactions(addresses, options={})
    self.get_address_transactions(addresses.join(','), options)
  end

  # Provide a Bitcoin address.
  # Returns all op_return data associated with address.
  def self.get_address_op_returns(address)
    get("/#{API_VERSION}/#{block_chain}/addresses/#{address}/op-returns")
  end

  # Provide a Bitcoin transaction.
  # Returns basic details for a Bitcoin transaction (hash).
  def self.get_transaction(hash)
    get("/#{API_VERSION}/#{block_chain}/transactions/#{hash}")
  end

  # Provide a Bitcoin transaction.
  # Returns the OP_RETURN string (if it exists) for a Bitcoin transaction(hash).
  def self.get_transaction_op_return(hash)
    get("/#{API_VERSION}/#{block_chain}/transactions/#{hash}/op-return")
  end

  # Provide a hex encoded, signed transaction.
  # Returns the newly created Bitcoin transaction hash (string).
  def self.send_transaction(hex)
    r = put("/#{API_VERSION}/#{block_chain}/transactions", {hex: hex})
    r["transaction_hash"]
  end

  # Provide a Bitcoin block hash or height.
  # Returns basic details for a Bitcoin block (hash).
  def self.get_block(hash_or_height)
    get("/#{API_VERSION}/#{block_chain}/blocks/#{hash_or_height}")
  end

  # Get latest Bitcoin block.
  # Returns basic details for latest Bitcoin block (hash).
  def self.get_latest_block
    get("/#{API_VERSION}/#{block_chain}/blocks/latest")
  end

  # Provide a Bitcoin block id.
  # Returns all op_return data contained in a block.
  def self.get_block_op_returns(hash_or_height)
    get("/#{API_VERSION}/#{block_chain}/blocks/#{hash_or_height}/op-returns")
  end

  def self.create_webhook(url, id=nil)
    body = {}
    body[:url] = url
    body[:id] = id unless id.nil?
    post("/#{API_VERSION}/webhooks", body)
  end

  def self.list_webhook_urls
    get("/#{API_VERSION}/webhooks")
  end

  def self.update_webhook_url(id, url)
    put("/#{API_VERSION}/webhooks/#{id}", {url: url})
  end

  def self.delete_webhook_url(id)
    delete("/#{API_VERSION}/webhooks/#{id}")
  end

  def self.create_webhook_event(id, opts={})
    body = {}
    body[:event] = opts[:event] || 'address-transaciton'
    body[:block_chain] = opts[:block_chain] || self.block_chain
    body[:address] = opts[:address] || raise(ChainError,
      "Must specify address when creating a Webhook Event.")
    body[:confirmations] = opts[:confirmations] || 1
    post("/#{API_VERSION}/webhooks/#{id}/events", body)
  end

  def self.list_webhook_events(id)
    get("/#{API_VERSION}/webhooks/#{id}/events")
  end

  def self.delete_webhook_event(id, event, address)
    delete("/#{API_VERSION}/webhooks/#{id}/events/#{event}/#{address}")
  end

  # Set the key with the value found in your settings page on https://chain.com
  # If no key is set, Chain's guest token will be used. The guest token
  # should not be used for production services.
  def self.api_key=(key)
    $stderr.puts("Chain.com is deprecating api_key. Use api_key_id.")
    @api_key = key
  end

  def self.api_key_id=(id)
    @api_key_id = id
  end

  def self.api_key_secret=(secret)
    @api_key_secret = secret
  end

  private

  def self.post(path, body)
    make_req!(Net::HTTP::Post, path, encode_body!(body))
  end

  def self.put(path, body)
    make_req!(Net::HTTP::Put, path, encode_body!(body))
  end

  def self.get(path, params={})
    path = path + "?" + URI.encode_www_form(params) unless params.empty?
    make_req!(Net::HTTP::Get, path)
  end

  def self.delete(path)
    make_req!(Net::HTTP::Delete, path)
  end

  def self.make_req!(type, path, body=nil)
    conn do |c|
      req = type.new(API_URL.request_uri + path)
      req.basic_auth(api_key_id, api_key_secret)
      req['Content-Type'] = 'application/json'
      req['User-Agent'] = 'chain-ruby/0'
      req.body = body
      resp = c.request(req)
      resp_code = Integer(resp.code)
      resp_body = parse_resp(resp)
      if resp_code / 100 != 2
        raise(ChainError, "HTTP Request Error: #{resp_body['message']}")
      end
      return resp_body
    end
  end

  def self.encode_body!(hash)
    begin
      JSON.dump(hash)
    rescue => e
      raise(ChainError, "JSON encoding error: #{e.message}")
    end
  end

  def self.parse_resp(resp)
      begin
        JSON.parse(resp.body)
      rescue => e
        raise(ChainError, "JSON decoding error: #{e.message}")
      end
  end

  def self.conn
    @conn ||= establish_conn
    @conn_mutex.synchronize do
      begin
        return yield(@conn)
      rescue => e
        @conn = nil
        raise(ChainError, "Connection error: #{e.message}")
      end
    end
  end

  def self.establish_conn
    Net::HTTP.new(API_URL.host, API_URL.port).tap do |c|
      c.use_ssl = true
      c.verify_mode = OpenSSL::SSL::VERIFY_PEER
      c.ca_file = CHAIN_PEM
    end
  end

  def self.api_key_id
    @api_key_id || api_key
  end

  def self.api_key_secret
    @api_key_secret || ''
  end

  def self.api_key
    @api_key || key_from_env || GUEST_KEY
  end

  def self.key_from_env
    if url = ENV['CHAIN_URL']
      URI.parse(url).user
    end
  end

  def self.block_chain=(net)
    @block_chain = net
  end

  def self.block_chain
    @block_chain || BLOCK_CHAIN
  end

end
