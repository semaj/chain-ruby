require 'bitcoin'

module Chain
  class Transaction
    MissingUnspentsError = Class.new(StandardError)
    MissingInputsError = Class.new(StandardError)

    def initialize(inputs: [], outputs: {}, fee: nil, change_address: nil)
      @inputs = strs_to_keys(inputs)
      @outputs = outputs
      @fee = fee
      @change_address = change_address

      validate!
    end

    def hex
      @hex ||= build_txn.to_payload.unpack('H*')[0]
    end

    def send
      Chain.send_transaction(hex)
    end

    def validate!
      raise(MissingInputsError) unless @inputs.length > 0
    end

    def strs_to_keys(priv_keys)
      keys = priv_keys.map{|pk| Bitcoin::Key.from_base58(pk)}
      Hash[keys.map{|key| [key.addr, key] }]
    end

    def unspents_amount
      unspents.map {|u| u["value"]}.reduce(:+)
    end

    def unspents
      @unspents ||= begin
        Chain.get_addresses_unspents(@inputs.keys).tap do |unspents|
          raise(MissingUnspentsError) if unspents.nil? or unspents.empty?
        end
      end
    end

    def outputs_amount
      @outputs.map {|addr, amount| amount}.reduce(:+)
    end

    def fee
      @fee || 10_000
    end

    def change
      unspents_amount - outputs_amount - fee
    end

    def change_address
      @change_address || @inputs.keys.first
    end

    def build_txn
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
          out.script {|s| s.recipient(@change_address)}
        end
      end

      builder.tx
    end

  end
end
