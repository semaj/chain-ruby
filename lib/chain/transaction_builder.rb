require 'btcruby'
module Chain
  # Chain::TransactionBuilder creates new transactions for the bitcoin network.
  # It inherits most of functionality from BTC::TransactionBuilder and adds Chain API
  # to fetch unspent outputs for a set of addresses.
  class TransactionBuilder < BTC::TransactionBuilder

    # Transaction is composed correctly.
    # inherited STATUS_OK

    # Change address is not specified
    # inherited STATUS_MISSING_CHANGE_ADDRESS

    # Unspent outputs are missing. Maybe because input_addresses are not specified.
    # inherited STATUS_MISSING_UNSPENT_OUTPUTS

    # Unspent outputs are not sufficient to build the transaction.
    # inherited STATUS_INSUFFICIENT_FUNDS

    # Input properties
    # ================

    # Addresses from which to fetch the inputs.
    # Could be base58-encoded address or BTC::Address instances.
    # If any address is a PrivateKeyAddress, the corresponding input will be automatically signed with SIGHASH_ALL.
    # Otherwise, the signature_script in the input will be set to output script from unspent output.
    # inherited attr_accessor :input_addresses

    # Actual available BTC::TransactionOutput's to spend.
    # If not specified, builder will fetch and remember unspent outputs
    # using #unspent_outputs_provider_block.
    # Only necessary inputs will be selected for spending.
    # If TransactionOutput#confirmations properties are not nil, outputs are sorted
    # from oldest to newest, unless #keep_unspent_outputs_order is set to true.
    # inherited attr_accessor :unspent_outputs

    # Data providing block with signature lambda{|addresses, outputs_amount, outputs_size, fee_rate|  [...] }
    # `addresses` is a list of BTC::Address instances.
    # `outputs_amount` is a total amount in satoshis to be spent in all outputs (not including change output).
    # `outputs_size` is a total size of all outputs in bytes (including change output).
    # `fee_rate` is a miner's fee per 1000 bytes.
    # Block returns an array of unspent BTC::TransactionOutput instances with non-nil #transaction_hash and #index.
    # Note: data provider may or may not use additional parameters as a hint
    # to select the best matching unspent outputs. If it takes into account these parameters,
    # it is responsible to provide enough unspent outputs to cover the resulting fee.
    # If outputs_amount is 0, all unspent outputs are expected to be returned.
    # inherited attr_accessor :unspent_outputs_provider_block

    # An array of BTC::TransactionOutput instances determining
    # how many coins to spend and how.
    # If the array is empty, all unspent outputs are spent to the change address.
    # inherited attr_accessor :outputs

    # Change address (base58-encoded string or BTC::Address).
    # Must be specified, but may not be used if change is too small.
    # inherited attr_accessor :change_address

    # Miner's fee per kilobyte (1000 bytes).
    # Default is Transaction::DEFAULT_FEE_RATE
    # inherited attr_accessor :fee_rate

    # Minimum amount of change below which transaction is not composed.
    # If change amount is non-zero and below this value, more unspent outputs are used.
    # If change amount is zero, change output is not even created and this property is not used.
    # Default value equals fee_rate.
    # inherited attr_accessor :minimum_change

    # Amount of change that can be forgone as a mining fee if there are no more
    # unspent outputs available. If equals zero, no amount is allowed to be forgone.
    # Default value equals minimum_change.
    # This means builder will never fail with "insufficient funds" just because it could not
    # find enough unspents for big enough change. In worst case it will forgo the change
    # as a part of the mining fee. Set to 0 to avoid wasting a single satoshi.
    # inherited attr_accessor :dust_change

    # If true, does not sort unspent_outputs by confirmations number.
    # Default is false, but order will be preserved if #confirmations property is nil.
    # inherited attr_accessor :keep_unspent_outputs_order


    # Result properties
    # =================

    # BTC::Transaction instance. Each input is either signed (if PrivateKeyAddress was used)
    # or contains an unspent output's script as its signature_script.
    # Unsigned inputs are marked using #unsigned_input_indices property.
    # Returns nil if there are not enough money in unspent outputs or
    # change address not provided.
    # inherited attr_reader :transaction

    # List of input indices that are not signed.
    # Empty list means all indices are signed.
    # Returns nil if there are not enough money in unspent outputs or
    # change address not provided.
    # inherited attr_reader :unsigned_input_indices

    # Status of the transaction: one of STATUS_* constants.
    # If transaction was built successfully, returns STATUS_OK
    # inherited attr_reader :status

    # Total fee for the composed transaction.
    # Equals (inputs_amount - outputs_amount)
    # inherited attr_reader :fee

    # Total amount on the inputs.
    # inherited attr_reader :inputs_amount

    # Total amount on the outputs.
    # inherited attr_reader :outputs_amount

    def unspent_outputs_provider_block
      @unspent_outputs_provider_block ||= proc do |addresses, outputs_amount, outputs_size, fee|
        load_utxos_for_addresses(addresses)
      end
    end

    private

    def load_utxos_for_addresses(addresses)
      Chain.default_client.get_addresses_unspents(addresses.map{|a| a.to_s}).tap do |unspents|
        (unspents || []).map do |dict|
          parse_utxo_from_dict(dict)
        end.compact # remove broken values (parse_utxo_from_dict returns nil for them)
      end || []
    end

    def parse_utxo_from_dict(dict)
      # {"transaction_hash"=>"0bf0de38c26195919179f42d475beb7a6b15258c38b57236afdd60a07eddd2cc",
      # "output_index"=>0,
      # "value"=>290000,
      # "addresses"=>[ "1K4nPxBMy6sv7jssTvDLJWk1ADHBZEoUVb" ],
      # "script"=>"OP_DUP OP_HASH160 c629680b8d13ca7a4b7d196360186d05658da6db OP_EQUALVERIFY OP_CHECKSIG",
      # "script_hex"=>"76a914c629680b8d13ca7a4b7d196360186d05658da6db88ac",
      # "script_type"=>"pubkeyhash",
      # "required_signatures"=>1,
      # "spent"=>false,
      # "confirmations"=>8758}

      if !(script_data = BTC::Data.data_from_hex(dict["script_hex"]))
        Diagnostics.current.add_message("Chain::TransactionBuilder: cannot decode script hex: #{dict['script_hex'].inspect}")
        return nil
      end

      if !(script = BTC::Script.with_data(script_data))
        Diagnostics.current.add_message("Chain::TransactionBuilder: invalid script binary: #{dict['script_hex'].inspect}")
        return nil
      end

      if !(txhash = BTC::Data.data_from_hex(dict["transaction_hash"])) || txhash.bytesize != 32
        Diagnostics.current.add_message("Chain::TransactionBuilder: invalid tx hash: #{dict['transaction_hash'].inspect}")
        return nil
      end

      if dict["spent"] && (dict["spent"] != false)
        Diagnostics.current.add_message("Chain::TransactionBuilder: utxo is marked as spent (remove logging of this message if that's expected behavior)")
        return nil
      end

      txout = TransactionOutput.new(value: dict["value"].to_i,
                                   script: script,
                         transaction_hash: txhash,
                                    index: dict["output_index"].to_i,
                            confirmations: dict["confirmations"].to_i)
      txout
    end # parse_utxo_from_dict

  end # TransactionBuilder
end # Chain