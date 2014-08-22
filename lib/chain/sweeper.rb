require 'bitcoin'

module Chain
  # Move all BTC from a list of addresses to a single address.
  # Private keys are kept in memory and not sent on the network.
  class Sweeper

    # Unable find unspent outputs for the addresses passed into from_keystrings.
    MissingUnspentsError = Class.new(StandardError)

    @@defaults = {
      fee: 10000
    }

    # Initializes a new object that is ready for sweeping.
    #from_keystrings:: Array of base58 encoded private keys. The unspent outputs of these keys will be consumed.
    #to_addr:: The base58 encoded hash of the public keys. The collection of unspent outputs will be sent to this address.
    #:opts[:fee] => 10000:: The fee used in the sweeping transaction.
    def initialize(from_keystrings, to_addr, opts = {})
      @options = @@defaults.merge(opts)
      @from_keys = strs_to_keys(from_keystrings)
      @to_addr = to_addr
    end

    # Creates a transactin and executes the network calls to perform the sweep.
    # 1. Uses Chain to fetch all unspent outputs associated with from_keystrings
    # 2. Create & Sign bitcoin transaction
    # 3. Sends the transaction to bitcoin network using Chain's API
    # Chain::ChainError will be raised if there is any netowrk related errors.
    def sweep!
      unspents = Chain.get_addresses_unspents(@from_keys.keys)
      raise(MissingUnspentsError) if unspents.nil? or unspents.empty?

      tx = build_txn(unspents)
      rawtx = tx.to_payload.unpack('H*')

      Chain.send_transaction(rawtx[0])
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
