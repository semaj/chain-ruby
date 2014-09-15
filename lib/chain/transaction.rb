require 'bitcoin'

module Chain
  # The Chain::Transaction is a mechanism to create new transactions
  # for the bitcoin network.
  class Transaction
    DEFAULT_FEE = 10_000
    MissingUnspentsError = Class.new(StandardError)
    MissingInputsError = Class.new(StandardError)
    InsufficientFundsError = Class.new(StandardError)

    # Create a new Transaction which will be ready for hex encoding and
    # subsequently delivery to the Chain API.
    # inputs:: Array of base58 encoded private keys. The unspent outputs of these keys will be consumed.
    # ouputs:: Hash with base58 encoded public key hashes keys and satoshi values.
    # fee:: Satoshi value representing the fee added to the transaction. Relies on DEFAULT_FEE when nil.
    # change_address:: Bash58 encoded hash of public key. To where change will be sent. See Transaction#change for details on how change is calculated.
    def initialize(inputs: [], outputs: {}, fee: nil, change_address: nil)
      @inputs = strs_to_keys(inputs)
      @outputs = outputs
      @fee = fee
      @change_address = change_address

      raise(MissingInputsError) unless @inputs.length > 0
    end

    # Returns the hex encoded transaction data.
    def hex
      @hex ||= build.to_payload.unpack('H*')[0]
    end

    # Send's the hex encoded transaction data to the Chain API.
    def send
      Chain.send_transaction(hex)
    end

    def strs_to_keys(priv_keys)
      keys = priv_keys.map{|pk| Bitcoin::Key.from_base58(pk)}
      Hash[keys.map{|key| [key.addr, key] }]
    end

    # Computes a sum of the values in the collectino of UTXO
    # associated with each address in the @inputs collection.
    def unspents_amount
      unspents.map {|u| u["value"]}.reduce(:+)
    end

    # Uses the Chain batch API to fetch unspents for @inputs.
    # Value is memoized for repeated access.
    def unspents
      @unspents ||= begin
        Chain.get_addresses_unspents(@inputs.keys).tap do |unspents|
          raise(MissingUnspentsError) if unspents.nil? or unspents.empty?
        end
      end
    end

    # Computes a sum of the outputs defined in the @outputs hash.
    def outputs_amount
      @outputs.map {|addr, amount| amount}.reduce(:+)
    end

    # Uses the fee specified in the initializer xor the DEFAULT_FEE
    def fee
      @fee || DEFAULT_FEE
    end

    def change
      unspents_amount - outputs_amount - fee
    end

    # Uses the address specified in the initializer. Otherwise
    # falls back on the first address in the list of @inputs.
    def change_address
      @change_address || @inputs.keys.first
    end

    # Consumes the unspents of the addresses in the @inputs
    # Creates outputs specifed by @outputs
    # Adds an additional output to the change_address if change is greater than 0.
    def build
      raise(InsufficientFundsError) if outputs_amount > unspents_amount

      builder  = Bitcoin::Builder::TxBuilder.new

      unspents.each do |unspent|
        builder.input do |inp|
          inp.prev_out        unspent["transaction_hash"]
          inp.prev_out_index  unspent["output_index"]
          inp.prev_out_script [unspent["script_hex"]].pack('H*')
          inp.signature_key   @inputs[unspent["addresses"][0]]
        end
      end

      @outputs.each do |addr, amount|
        builder.output do |out|
          out.value amount
          out.script {|s| s.recipient(addr)}
        end
      end

      unless change.zero?
        builder.output do |out|
          out.value change
          out.script {|s| s.recipient(change_address)}
        end
      end

      builder.tx
    end

  end
end
