module Chain
  class Client

    # Type of Bitcoin network.
    # Possible values: NETWORK_MAINNET and NETWORK_TESTNET.
    # Default is NETWORK_MAINNET.
    attr_accessor :network

    # Base URL to access Chain.com (String or URI instance).
    attr_accessor :url

    # String key identifier.
    attr_accessor :api_key_id

    # String key secret.
    attr_accessor :api_key_secret

    # `url` specifies a base URL to access Chain.com. If not specified, Chain.default_url is used.
    # `api_key_id` specifies your key id. If not specified, 'user' fragment of the `url`
    # is used (if present) or GUEST_KEY_ID.
    # `api_key_secret` specifies a secret counterpart of the key. If not specified, 'password'
    # fragment of the `url` is used.
    # `network` is either NETWORK_MAINNET or NETWORK_TESTNET.
    # Note: Guest tokens are limited in their access to the Chain API.
    def initialize(url: nil, api_key_id: nil, api_key_secret: nil, network: NETWORK_MAINNET)
      @url            = URI(url    || Chain.default_url)
      @api_key_id     = api_key_id     || url.user || GUEST_KEY_ID
      @api_key_secret = api_key_secret || url.password
      @network        = network    || NETWORK_MAINNET
      @conn = Connection.new(@url, @api_key_id, @api_key_secret)
    end

    def url=(url)
      @url = url ? URI(url) : nil
      @api_key_id = @url.user if @url && @url.user
      @api_key_secret = @url.password if @url && @url.password
    end

    def testnet?
      @network == NETWORK_TESTNET
    end

    def mainnet?
      @network == NETWORK_MAINNET
    end


    #
    # ADDRESS API
    # ===========


    # Returns an AddressInfo object describing a given address (BTC::Address or string in Base58Check format)
    def get_address(address)
      get_addresses([address]).first
    end

    # Returns an array of AddressInfo objects about given addresses
    # (BTC::Address instances or strings in Base58Check format)
    def get_addresses(addresses)
      addrs = addresses.map{|addr| addr.to_s }.join(",")
      dict_or_array = @conn.get("/#{API_VERSION}/#{network}/addresses/#{addrs}")
      array = !dict_or_array.is_a?(Array) ? [dict_or_array] : dict_or_array
      array.map{|dict| AddressInfo.new(dictionary: dict) }
    end

    # Returns all unspent outputs (BTC::TransactionOutput) for a given address
    # (base58 strings or BTC::Address instances).
    # Each output has the following optional properties set:
    # — transaction_hash (binary hash of the transaction)
    # — transaction_id (reversed transaction hash as a hex string)
    # — index (index of the output in its transaction)
    # - confirmations (number of blocks, 0 for unconfirmed outputs)
    def get_address_unspents(address)
      get_addresses_unspents([address])
    end

    # Returns all unspent outputs (BTC::TransactionOutput) for a given list of addresses
    # (base58 strings or BTC::Address instances).
    # Each output has the following optional properties set:
    # `transaction_hash` (binary hash of the transaction)
    # `transaction_id` (reversed transaction hash as a hex string)
    # `index` (index of the output in its transaction)
    # `confirmations` (number of blocks, 0 for unconfirmed outputs)
    def get_addresses_unspents(addresses)
      addrs = addresses.map{|addr| addr.to_s }.join(",")
      array = @conn.get("/#{API_VERSION}/#{network}/addresses/#{addrs}/unspents")
      array.map do |dict|
        txout = BTC::TransactionOutput.new
        txout.value          = dict["value"].to_i
        txout.script         = BTC::Script.with_data(BTC::Data.data_from_hex(dict["script_hex"]))
        txout.transaction_id = dict["transaction_hash"]
        txout.index          = dict["output_index"].to_i
        txout.confirmations  = dict["confirmations"].to_i
        txout.spent          = false
        txout
      end
    end

    DEFAULT_TRANSACTIONS_LIMIT = 50
    MAX_TRANSACTIONS_LIMIT = 200

    # Returns a list BTC::Transaction (most recent first) for a given address.
    # Address could be a String in Base58Check format or a BTC::Address instance.
    # Amount of transactions returned is limited by `limit` argument.
    # Each transaction instance has these additional informational properties:
    # `block_hash` — the binary hash of the block containing the transaction.
    # `block_height` – the height of the block containing the transaction.
    #  The height of a block is the distance from the first block in the chain (height = 0).
    #  Contains nil for unconfirmed transactions.
    # `block_time` — the UTC time (Time object) at which the block containing the transaction was created by the miner.
    #  Contains nil for unconfirmed transactions.
    # `confirmations` - number of confirmations. 0 for unconfirmed transactions.
    # `amount` — The total amount of the transaction in satoshis.
    #  This is equal to total of all output values (or the total of all input values minus the miner fees).
    # `fees` — The total fees paid to the miner in satoshis. This is not included in the transaction `amount`.
    # `chain_received_at` — The UTC time at which Chain.com indexed this transaction.
    #  Note that transactions confirmed prior to June 2014 will have this value = nil.
    #  Therefore, when sorting transactions by this time, you should fall back on `block_time`.
    #
    # Each output (BTC::TransactionOutput) contains an additional property `spent` which is true or false depending on
    # whether the output is spent in any known (including unconfirmed) transaction.
    def get_address_transactions(address, limit: DEFAULT_TRANSACTIONS_LIMIT)
      get_addresses_transactions([address], limit: limit)
    end

    # Returns a list BTC::Transaction (most recent first) for the given addresses.
    # Each address could be a String in Base58Check format or a BTC::Address instance.
    # Amount of transactions returned is limited by `limit` argument.
    def get_addresses_transactions(addresses, limit: DEFAULT_TRANSACTIONS_LIMIT)
      if limit > MAX_TRANSACTIONS_LIMIT
        $stderr.puts "Chain::Client#get_addresses_transactions: maximum `limit` value is #{MAX_TRANSACTIONS_LIMIT}."
        limit = MAX_TRANSACTIONS_LIMIT
      end
      addrs = addresses.map{|addr| addr.to_s }.join(",")
      url = "/#{API_VERSION}/#{network}/addresses/#{addrs}/transactions"
      array = @conn.get(url, {limit: limit})
      array.map do |dict|
        BTC::Transaction.with_chain_dictionary(dict)
      end
    end

    # Returns an array of OpReturnInfo objects describing OP_RETURN outputs for a given address.
    # Address could be a String in Base58Check format or a BTC::Address instance.
    def get_address_op_returns(address)
      address = address.to_s
      url = "/#{API_VERSION}/#{network}/addresses/#{address}/op-returns"
      list = @conn.get(url)
      list.map do |dict|
        OpReturnInfo.new(dictionary: dict)
      end
    end





    #
    # TRANSACTION API
    # ===============



    # Returns BTC::Transaction instance for a given transaction ID (reversed hex hash).
    # Transaction instance has these additional informational properties:
    # `block_hash` — the binary hash of the block containing the transaction.
    # `block_height` – the height of the block containing the transaction.
    #  The height of a block is the distance from the first block in the chain (height = 0).
    #  Contains nil for unconfirmed transactions.
    # `block_time` — the UTC time (Time object) at which the block containing the transaction was created by the miner.
    #  Contains nil for unconfirmed transactions.
    # `confirmations` - number of confirmations. 0 for unconfirmed transactions.
    # `amount` — The total amount of the transaction in satoshis.
    #  This is equal to total of all output values (or the total of all input values minus the miner fees).
    # `fees` — The total fees paid to the miner in satoshis. This is not included in the transaction `amount`.
    # `chain_received_at` — The UTC time at which Chain.com indexed this transaction.
    #  Note that transactions confirmed prior to June 2014 will have this value = nil.
    #  Therefore, when sorting transactions by this time, you should fall back on `block_time`.
    #
    # Each output (BTC::TransactionOutput) contains an additional property `spent` which is true or false depending on
    # whether the output is spent in any known (including unconfirmed) transaction.
    def get_transaction(txid)
      dict = @conn.get("/#{API_VERSION}/#{network}/transactions/#{txid}")
      return BTC::Transaction.with_chain_dictionary(dict)
    end

    # Returns a single OpReturnInfo object for a given transaction (identified by transaction ID)
    # Returns nil if transaction does not have an OP_RETURN output.
    def get_transaction_op_return(txid)
      # curl https://api.chain.com/v2/bitcoin/transactions/4a7d62a4a5cc912605c46c6a6ef6c4af451255a453e6cbf2b1022766c331f803/op-return?api-key-id=DEMO-4a5e1e4
      # => {"transaction_hash":"4a7d62a4a5cc912605c46c6a6ef6c4af451255a453e6cbf2b1022766c331f803",
      #     "hex":"436861696e2e636f6d202d2054686520426c6f636b20436861696e20415049",
      #     "text":"Chain.com - The Block Chain API",
      #     "receiver_addresses":["1Bj5UVzWQ84iBCUiy5eQ1NEfWfJ4a3yKG1"],
      #     "sender_addresses":["1Bj5UVzWQ84iBCUiy5eQ1NEfWfJ4a3yKG1"]}
      # curl https://api.chain.com/v2/bitcoin/transactions/0f40015ddbb8a05e26bbacfb70b6074daa1990b813ba9bc70b7ac5b0b6ee2c45/op-return?api-key-id=DEMO-4a5e1e4
      # => {"message":"Unable to find transaction.","code":"CH201"}
      dict = @conn.get("/#{API_VERSION}/#{network}/transactions/#{txid}/op-return")
      if dict["transaction_hash"]
        return OpReturnInfo.new(dictionary: dict)
      else
        return nil
      end
    end

    # Broadcasts a transaction (BTC::Transaction instance) to the Bitcoin network.
    # Returns the newly created Bitcoin transaction id or raises ChainBroadcastError if
    # transaction is malformed, invalid or contains non-canonical data.
    def send_transaction(tx)
      hex = BTC::Data.hex_from_data(tx.data)
      begin
        r = @conn.put("/#{API_VERSION}/#{network}/transactions", {hex: hex})
        # In case of rejection, this is what returned with 400 code:
        # {"message":"Transaction rejected.","code":"CH202"}
        if txid = r["transaction_hash"]
          return txid
        else
          raise ChainBroadcastError, ((r ? r["message"] : nil) || "Unknown error")
        end
      rescue ChainNetworkError => e
        if e.http_code == 400 # if it's a rejection error, wrap in 'broadcast error'
          raise ChainBroadcastError, e.message
        else
          raise e
        end
      end
    end



    # BLOCK API
    # =========


    # Returns BTC::Block object for a given height or block ID (reversed block hash in hex format)
    def get_block(id_or_height)
      dict = @conn.get("/#{API_VERSION}/#{network}/blocks/#{id_or_height}")
      BTC::Block.with_chain_dictionary(dict, chain_client: self)
    end

    # Returns BTC::Block object for the latest known block.
    def get_latest_block
      dict = @conn.get("/#{API_VERSION}/#{network}/blocks/latest")
      BTC::Block.with_chain_dictionary(dict, chain_client: self)
    end

    # Returns an array of OpReturnInfo objects describing OP_RETURN outputs for a given block.
    # You may identify the block by its height or block ID (reversed block hash in hex format)
    def get_block_op_returns(id_or_height)
      url = "/#{API_VERSION}/#{network}/blocks/#{id_or_height}/op-returns"
      list = @conn.get(url)
      list.map do |dict|
        OpReturnInfo.new(dictionary: dict)
      end
    end





    # NOTIFICATIONS API
    # =================







    # Webhooks
    # ========


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
      body[:address] = opts[:address] || raise(ArgumentError,
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
