module Chain
  # Information about an OP_RETURN data.
  # Use Client#get_address_op_returns to access this data.
  class OpReturnInfo

    # The transaction ID where this OP_RETURN is found
    attr_reader :transaction_id
    
    # The transaction hash (32-byte binary hash)
    attr_reader :transaction_hash

    # Binary data encoded in the OP_RETURN output.
    attr_reader :data

    # UTF-8 string decoded in the OP_RETURN output.
    attr_reader :text

    # List of addresses (BTC::Address) associated with the inputs of the transaction.
    attr_reader :sender_addresses

    # List of addresses (BTC::Address) associated with the outputs of the transaction.
    attr_reader :receiver_addresses
    
    def initialize(dictionary: {})
      @transaction_id = ensure_type(dictionary["transaction_hash"], String)
      @data = BTC::Data.data_from_hex(ensure_type(dictionary["hex"], String))
      @text = dictionary["text"] ? ensure_type(dictionary["text"], String) : nil
      @sender_addresses = ensure_type(dictionary["sender_addresses"], Array).map do |addr|
        BTC::Address.with_string(ensure_type(addr, String))
      end
      @receiver_addresses = ensure_type(dictionary["receiver_addresses"], Array).map do |addr|
        BTC::Address.with_string(ensure_type(addr, String))
      end
    end
    
    def transaction_hash
      @transaction_hash ||= BTC.hash_from_id(@transaction_id)
    end

    private

    def ensure_type(value, type)
      if value.is_a?(type)
        value
      else
        raise ChainFormatError, "Expected value of type #{type}, got #{value.class} (#{value.inspect})"
      end
    end

  end
end
