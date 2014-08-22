require 'bitcoin'

module Chain
  class Sweeper
    @@defaults = {
      fee: 10000
    }

    def initialize(from_keystrings, to_addr, opts = {})
      @options = @@defaults.merge(opts)
      @from_keys = strs_to_keys(from_keystrings)
      @to_addr = to_addr
    end

    def sweep!
      unspents = Chain.get_addresses_unspents(@from_keys.keys)
      raise "Unspents empty or nil".inspect if unspents.nil? or unspents.empty?

      tx = build_txn(unspents)
      rawtx = tx.to_payload.unpack('H*')

      Chain.send_transaction(rawtx)
    end

    private

    def strs_to_keys(priv_keys)
      keys = priv_keys.map{|pk| Bitcoin::Key.from_base58(pk)}
      Hash[keys.map{|key| [key.addr, key] }]
    end

    def build_txn(unspents)
      builder  = Bitcoin::Builder::TxBuilder.new
      amount = unspents.map {|u| u["value"]}.reduce(:+)

      unspents.each do |unspent|
        builder.input do |inp|
          inp.prev_out        unspent["transaction_hash"]
          inp.prev_out_index  unspent["output_index"]
          inp.prev_out_script [unspent["script_hex"]].pack('H*')
          inp.signature_key   @from_keys[unspent["addresses"][0]]
        end
      end

      builder.output do |out|
        out.value (amount - @options[:fee])
        out.script {|s| s.recipient @to_addr }
      end

      builder.tx
    end

  end
end
