require 'btcruby'

# Chain-specific extensions to BTC::Transaction
module BTC
  BTC::Transaction # make sure class is loaded with its proper superclass.
  class Transaction
    # The UTC time at which Chain.com indexed this transaction.
    # Note that transactions confirmed prior to June 2014 will have this value = nil.
    # Therefore, when sorting transactions by this time, you should fall back on `block_time`.
    attr_accessor :chain_received_at

    def self.with_chain_dictionary(dict)
      tx = BTC::Transaction.new

      received_hash = BTC.hash_from_id(dict["hash"])

      dict["inputs"].each do |input_dict|
        txin = BTC::TransactionInput.new
        txin.previous_hash = BTC.hash_from_id(input_dict["output_hash"]) if input_dict["output_hash"]
        txin.previous_index = input_dict["output_index"].to_i if input_dict["output_index"]

        # TODO: this API also is not 100% robust as we have to parse a fuzzy string representation of the script.
        txin.addresses = (input_dict["addresses"] || []).map{|a| BTC::Address.with_string(a) }
        
        if !input_dict["script_signature"] && input_dict["coinbase"]
          txin.coinbase_data = BTC::Data.data_from_hex(input_dict["coinbase"])
        else
          parts = input_dict["script_signature"].split(" ").map do |part|
            if part.to_i.to_s == part # support "0" prefix.
              BTC::Opcode.opcode_for_small_integer(part.to_i)
            else
              BTC::Data.data_from_hex(part)
            end
          end
          txin.signature_script = (BTC::Script.new << parts)
        end
        txin.value = input_dict["value"].to_i
        tx.add_input(txin)
      end

      dict["outputs"].each do |output_dict|
        txout = BTC::TransactionOutput.new
        txout.value = output_dict["value"].to_i
        txout.script = BTC::Script.with_data(BTC::Data.data_from_hex(output_dict["script_hex"]))
        txout.spent = output_dict["spent"]
        txout.addresses = (output_dict["addresses"] || []).map{|a| BTC::Address.with_string(a) }
        tx.add_output(txout)
      end

      # Check that hash of the resulting tx is the same as received one.
      if tx.transaction_hash != received_hash
        raise ChainFormatError, "Cannot build exact copy of a transaction from JSON response"
      end

      tx.block_hash = BTC.hash_from_id(dict["block_hash"]) # block hash is reversed hex like txid.
      tx.block_height = dict["block_height"].to_i
      tx.block_time = dict["block_time"] ? Time.parse(dict["block_time"]) : nil
      tx.confirmations = dict["confirmations"].to_i
      tx.fee = dict["fees"] ? dict["fees"].to_i : nil
      tx.chain_received_at = dict["chain_received_at"] ? Time.parse(dict["chain_received_at"]) : nil
      tx
    end
  end # BTC::Transaction
end


# module Chain
#   # The Chain::Transaction is a mechanism to create new transactions
#   # for the bitcoin network.
#   class Transaction
#     DEFAULT_FEE = 10_000
#     MissingUnspentsError = Class.new(StandardError)
#     MissingInputsError = Class.new(StandardError)
#     InsufficientFundsError = Class.new(StandardError)
#
#     # Create a new Transaction which will be ready for hex encoding and
#     # subsequently delivery to the Chain API.
#     # inputs:: Array of base58 encoded private keys. The unspent outputs of these keys will be consumed.
#     # ouputs:: Hash with base58 encoded public key hashes keys and satoshi values.
#     # fee:: Satoshi value representing the fee added to the transaction. Relies on DEFAULT_FEE when nil.
#     # change_address:: Bash58 encoded hash of public key. To where change will be sent. See Transaction#change for details on how change is calculated.
#     def initialize(inputs: [], outputs: {}, fee: nil, change_address: nil)
#       @inputs = strs_to_keys(inputs)
#       @outputs = outputs
#       @fee = fee
#       @change_address = change_address
#
#       raise(MissingInputsError) unless @inputs.length > 0
#     end
#
#     # Returns the hex encoded transaction data.
#     def hex
#       @hex ||= build.to_payload.unpack('H*')[0]
#     end
#
#     # Send's the hex encoded transaction data to the Chain API.
#     def send
#       Chain.send_transaction(hex)
#     end
#
#     def strs_to_keys(priv_keys)
#       keys = priv_keys.map{|pk| Bitcoin::Key.from_base58(pk)}
#       Hash[keys.map{|key| [key.addr, key] }]
#     end
#
#     # Computes a sum of the values in the collectino of UTXO
#     # associated with each address in the @inputs collection.
#     def unspents_amount
#       unspents.map {|u| u["value"]}.reduce(:+)
#     end
#
#     # Uses the Chain batch API to fetch unspents for @inputs.
#     # Value is memoized for repeated access.
#     def unspents
#       @unspents ||= begin
#         Chain.get_addresses_unspents(@inputs.keys).tap do |unspents|
#           raise(MissingUnspentsError) if unspents.nil? or unspents.empty?
#         end
#       end
#     end
#
#     # Computes a sum of the outputs defined in the @outputs hash.
#     def outputs_amount
#       @outputs.map {|addr, amount| amount}.reduce(:+)
#     end
#
#     # Uses the fee specified in the initializer xor the DEFAULT_FEE
#     def fee
#       @fee || DEFAULT_FEE
#     end
#
#     def change
#       unspents_amount - outputs_amount - fee
#     end
#
#     # Uses the address specified in the initializer. Otherwise
#     # falls back on the first address in the list of @inputs.
#     def change_address
#       @change_address || @inputs.keys.first
#     end
#
#     # Consumes the unspents of the addresses in the @inputs
#     # Creates outputs specifed by @outputs
#     # Adds an additional output to the change_address if change is greater than 0.
#     def build
#       raise(InsufficientFundsError) if outputs_amount > unspents_amount
#
#       builder  = Bitcoin::Builder::TxBuilder.new
#
#       unspents.each do |unspent|
#         builder.input do |inp|
#           inp.prev_out        unspent["transaction_hash"]
#           inp.prev_out_index  unspent["output_index"]
#           inp.prev_out_script [unspent["script_hex"]].pack('H*')
#           inp.signature_key   @inputs[unspent["addresses"][0]]
#         end
#       end
#
#       @outputs.each do |addr, amount|
#         builder.output do |out|
#           out.value amount
#           out.script {|s| s.recipient(addr)}
#         end
#       end
#
#       # If the caller supplies a fee, we should use that,
#       # instead of using the default.
#       if @fee and change > 0
#         builder.output do |out|
#           out.value change
#           out.script {|s| s.recipient(change_address)}
#         end
#         builder.tx
#       else
#         builder.tx(change_address: change_address, input_value: unspents_amount)
#       end
#     end
#
#   end
# end
