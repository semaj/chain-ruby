module Chain
  class Client
    
    NETWORK_MAINNET = "bitcoin".freeze
    NETWORK_TESTNET = "testnet3".freeze
    
    # Type of Bitcoin network. Default is NETWORK_MAINNET.
    attr_accessor :network
    
    # Base URL to access Chain.com (String or URI instance).
    attr_accessor :url
    
    # String key identifier.
    attr_accessor :key_id
    
    # String key secret.
    attr_accessor :key_secret

    # `url` specifies a base URL to access Chain.com. If not specified, Chain.default_url is used.
    # `key_id` specifies your key id. If not specified, 'user' fragment of the `url` 
    # is used (if present) or GUEST_KEY_ID.
    # `key_secret` specifies a secret counterpart of the key. If not specified, 'password'
    # fragment of the `url` is used.
    # `network` is either NETWORK_MAINNET or NETWORK_TESTNET.
    # Note: Guest tokens are limited in their access to the Chain API.
    def initialize(url: nil, key_id: nil, key_secret: nil, network: NETWORK_MAINNET)
      @url        = URI(url    || Chain.default_url)
      @key_id     = key_id     || url.user || GUEST_KEY_ID
      @key_secret = key_secret || url.password
      @network    = network    || NETWORK_MAINNET
      @conn = Connection.new(url, key_id, key_secret)
    end
    
    def url=(url)
      if url
        @url = URI(url)
        @key_id = @url.user if @url.user
        @key_secret = @url.password if @url.password
      else
        @url = nil
        @key_id = nil
        @key_secret = nil
      end
    end
    
    # Provide a Bitcoin address.
    # Returns basic details for a Bitcoin address (hash).
    def get_address(address)
      @conn.get("/#{API_VERSION}/#{block_chain}/addresses/#{address}")
    end

    # Provide an array of Bitcoin addresses.
    # Returns an array of basic details for a set of Bitcoin address (hash).
    def get_addresses(addresses)
      get_address(addresses.join(','))
    end

    # Provide a Bitcoin address.
    # Returns unspent transaction outputs for a Bitcoin address
    # (array of hashes).
    def get_address_unspents(address)
      @conn.get("/#{API_VERSION}/#{block_chain}/addresses/#{address}/unspents")
    end

    # Provide an array of Bitcoin addresses.
    # Returns an array of unspent transaction outputs
    # for a set of Bitcoin address (array of hashes).
    def get_addresses_unspents(addresses)
      get_address_unspents(addresses.join(','))
    end

    # Provide a Bitcoin address.
    # Returns transactions for a Bitcoin address (array of hashes).
    def get_address_transactions(address, options={})
      url = "/#{API_VERSION}/#{block_chain}/addresses/#{address}/transactions"
      @conn.get(url, options)
    end

    # Provide an array of Bitcoin address.
    # Returns an array of transactions for a set of Bitcoin address
    # (array of hashes).
    def get_addresses_transactions(addresses, options={})
      get_address_transactions(addresses.join(','), options)
    end

    # Provide a Bitcoin address.
    # Returns all op_return data associated with address.
    def get_address_op_returns(address)
      url = "/#{API_VERSION}/#{block_chain}/addresses/#{address}/op-returns"
      @conn.get(url)
    end

    # Provide a Bitcoin transaction.
    # Returns basic details for a Bitcoin transaction (hash).
    def get_transaction(hash)
      @conn.get("/#{API_VERSION}/#{block_chain}/transactions/#{hash}")
    end

    # Provide a Bitcoin transaction.
    # Returns the OP_RETURN string (if it exists) for a Bitcoin
    # transaction(hash).
    def get_transaction_op_return(hash)
      @conn.get("/#{API_VERSION}/#{block_chain}/transactions/#{hash}/op-return")
    end

    # Provide a hex encoded, signed transaction.
    # Returns the newly created Bitcoin transaction hash (string).
    def send_transaction(hex)
      r = @conn.put("/#{API_VERSION}/#{block_chain}/transactions", {hex: hex})
      r["transaction_hash"]
    end

    # Provide a Bitcoin block hash or height.
    # Returns basic details for a Bitcoin block (hash).
    def get_block(hash_or_height)
      @conn.get("/#{API_VERSION}/#{block_chain}/blocks/#{hash_or_height}")
    end

    # Get latest Bitcoin block.
    # Returns basic details for latest Bitcoin block (hash).
    def get_latest_block
      @conn.get("/#{API_VERSION}/#{block_chain}/blocks/latest")
    end

    # Provide a Bitcoin block id.
    # Returns all op_return data contained in a block.
    def get_block_op_returns(hash_or_height)
      url = "/#{API_VERSION}/#{block_chain}/blocks/#{hash_or_height}/op-returns"
      @conn.get(url)
    end

    def create_webhook(url, id=nil)
      body = {}
      body[:url] = url
      body[:id] = id unless id.nil?
      @conn.post("/#{API_VERSION}/webhooks", body)
    end
    alias_method :create_webhook_url, :create_webhook

    def list_webhooks
      @conn.get("/#{API_VERSION}/webhooks")
    end
    alias_method :list_webhook_url, :list_webhooks

    def update_webhook(id, url)
      @conn.put("/#{API_VERSION}/webhooks/#{id}", {url: url})
    end
    alias_method :update_webhook_url, :update_webhook

    def delete_webhook(id)
      @conn.delete("/#{API_VERSION}/webhooks/#{id}")
    end
    alias_method :delete_webhook_url, :delete_webhook

    def create_webhook_event(id, opts={})
      body = {}
      body[:event] = opts[:event] || 'address-transaction'
      body[:block_chain] = opts[:block_chain] || block_chain
      body[:address] = opts[:address] || raise(ChainError,
        "Must specify address when creating a Webhook Event.")
      body[:confirmations] = opts[:confirmations] || 1
      @conn.post("/#{API_VERSION}/webhooks/#{id}/events", body)
    end

    def list_webhook_events(id)
      @conn.get("/#{API_VERSION}/webhooks/#{id}/events")
    end

    def delete_webhook_event(id, event, address)
      @conn.delete("/#{API_VERSION}/webhooks/#{id}/events/#{event}/#{address}")
    end

    # Provide a destination address.
    # Returns a payment address that will automatically forward to the
    # destination address when funds are sent to it.
    # If Webhook parameters are provided, a Webhook event will be created
    # to notify your server when funds are sent to the payment address.
    def create_payment_address(dest_addr, body={})
      body[:destination_address] = dest_addr
      body[:block_chain] ||= block_chain
      @conn.post("/#{API_VERSION}/payments", body)
    end

    def payments
      @conn.get("/#{API_VERSION}/payments")
    end

  end
end
