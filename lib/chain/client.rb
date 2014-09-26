module Chain
  class Client

    attr_accessor :block_chain

    # url, key_id, and key_secret can be configured by
    # passing them in the options hash. Otherwise they will be read
    # from the environment. Finally, if the environment does not contain
    # these values they will be filled in the the guest token information.
    # Guest tokens are limited in their access to the Chain API.
    def initialize(opts={})
      url = URI(opts[:url] || Chain.url)
      key_id = opts[:key_id] || url.user || Chain.url.user
      key_secret = opts[:key_secret] || url.password || Chain.url.password
      @block_chain = opts[:block_chain] || Chain.block_chain
      @conn = Conn.new(url, key_id, key_secret)
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

    def create_webhook(type, url, opts={})
      type || 'address-transaction'
      url || raise(ChainError,
        "Must specify a Webhook URL.")
      body = {}
      body[:address] = opts[:address] || raise(ChainError,
        "Must specify a address.")
      body[:confirmations] = opts[:confirmations] || 1
      @conn.post("/#{API_VERSION}/webhooks/#{type}", body)
    end

    def list_webhooks
      @conn.get("/#{API_VERSION}/webhooks")
    end

    def delete_webhook(id)
      @conn.delete("/#{API_VERSION}/webhooks/#{id}")
    end

    def trigger_webhook(id)
      @conn.post("/#{API_VERSION}/webhooks/#{id}/trigger")
    end

  end
end
