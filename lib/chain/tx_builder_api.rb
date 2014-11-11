class TransactionBuilderAPI

  DEFAULT_FEE_RATE = 10000

  attr_accessor :client

  def client
    @client || Chain.default_client
  end

  # 1. Client posts info about transaction they want to build and gets back info about
  #    hashes to sign and unsigned transaction itself.
  #
  #    POST /v2/transactions
  #    {
  #      "inputs": [
  #        "1address1",
  #        "3address2"
  #      ],
  #      "outputs": [
  #        {
  #          "address": "1address3",
  #          "amount": 1000
  #        },
  #        {
  #          "address": "1address4",
  #          "amount": 2000
  #        }
  #      ],
  #      "change_address": "1address5",
  #      "miner_fee_rate": 5000,
  #      "min_confirmations": 6
  #    }
  #
  # Response: unsigned transaction and info about required signatures (SIGHASH_ALL by default)
  # {
  #   "inputs_to_sign": [
  #     {
  #       "address": "1address1",
  #       "hash_to_sign": "0327549...",
  #       "signature": "!---insert-signature---!",
  #       "public_key": "!---insert-public-key---!"
  #     },
  #     {
  #       "address": "3address2",
  #       "hash_to_sign": "0426434...",
  #       "signatures": ["!---insert-first-signature---!", "..."],
  #       "public_keys": ["!---insert-first-public-key---!", "..."]
  #     }
  #   ],
  #   "unsigned_transaction": {
  #     "hex": "0100000001ec...",
  #     "amount": 50000,
  #     "miner_fee": 10000
  #   }
  # }
  def build_transaction(dict)
    if !dict["inputs"] || dict["inputs"].size == 0
      return {
          "message" => "At least one input required.",
          "code" => "CH?01",
      }
    end
    if !dict["outputs"] || dict["outputs"].size == 0
      return {
          "message" => "At least one output required.",
          "code" => "CH?02",
      }
    end
    if !dict["change_address"]
      return {
          "message" => "Change address is required.",
          "code" => "CH?03",
      }
    end

    # Will use to check that all addresses belong to mainnet or testnet.
    all_addresses = []

    input_addresses = dict["inputs"].map{|addr| BTC::Address.with_string(addr) }
    if input_addresses.include?(nil)
      return {
          "message" => "Invalid input address format.",
          "code" => "CH300"
      }
    end

    input_addresses = input_addresses.map{|a| a.public_address }

    all_addresses += input_addresses

    outputs = dict["outputs"].map do |outdict|
      script = nil
      if outdict["address"]
        addr = BTC::Address.with_string(outdict["address"])
        if addr == nil
          return {
              "message" => "Invalid output address format.",
              "code" => "CH300"
          }
        end
        all_addresses << addr
        script = addr.script
      elsif outdict["script"]
        script = BTC::Script.with_data(BTC::Data.data_from_hex(outdict["script"]))
        if script == nil
          return {
              "message" => "Invalid output script encoding.",
              "code" => "CH???"
          }
        end
      else
        return {
            "message" => "Output must contain an address or a hex-encoded script.",
            "code" => "CH?04"
        }
      end

      amount = outdict["amount"]
      if amount == nil
        return {
            "message" => "Output must contain amount in satoshis.",
            "code" => "CH?05"
        }
      end

      # Allow zero amount only for OP_RETURN scripts
      if amount == 0
        if script.to_a.first != BTC::OP_RETURN
          return {
              "message" => "Output amount must be greater than zero.",
              "code" => "CH300"
          }
        end
      end

      BTC::TransactionOutput.new(value: amount, script: script)
    end

    change_address = BTC::Address.with_string(dict["change_address"])

    if change_address == nil
      return {
          "message" => "Invalid change address format.",
          "code" => "CH300"
      }
    end

    all_addresses << change_address

    # Check that all addresses belong either to mainnet or testnet
    if all_addresses.map{|a| a.mainnet? }.uniq.size > 1
      return {
          "message" => "Transaction cannot include multiple block chains",
          "code" => "CH?06"
      }
    end

    fee_rate = dict["miner_fee_rate"] || DEFAULT_FEE_RATE
    min_confirmations = dict["min_confirmations"] || 0

    client = self.client.dup
    client.network = change_address.mainnet? ? Chain::NETWORK_MAINNET : Chain::NETWORK_TESTNET

    builder = BTC::TransactionBuilder.new
    builder.unspent_outputs_provider_block = proc do |addresses, outputs_amount, outputs_size, fee|
      unspents = client.get_addresses_unspents(addresses).find_all do |txout|
        txout.confirmations >= min_confirmations
      end
    end

    builder.input_addresses = input_addresses
    builder.outputs = outputs
    builder.change_address = change_address
    builder.fee_rate = fee_rate

    result = nil
    begin
      result = builder.build
    rescue TransactionBuilderMissingUnspentOutputsError => e
      return {
          "message" => "Insufficient funds.",
          "code" => "CH?07"
      }
    rescue TransactionBuilderInsufficientFundsError => e
      return {
          "message" => "Insufficient funds.",
          "code" => "CH?07"
      }
    end

    response = {}

    tx = result.transaction
    i = 0
    response["inputs_to_sign"] = tx.inputs.map do |txin|
      utxo = txin.transaction_output
      d = {
        "address"      => utxo.script.standard_address(testnet: !change_address.mainnet?).to_s,
        "hash_to_sign" => BTC::Data.hex_from_data(tx.signature_hash(input_index: i,
                                                                    output_script: utxo.script,
                                                                    hash_type: BTC::SIGHASH_ALL)),
      }
      if i == 0
        d["signature"] = "!---insert-signature---!"
        d["public_key"] = "!---insert-public-key---!"
      else
        d["signatures"] = ["!---insert-first-signature---!", "..."]
        d["public_keys"] = ["!---insert-first-public-key---!", "..."]
      end
      i += 1
      d
    end

    response["unsigned_transaction"] = {
      "hex" => BTC::Data.hex_from_data(result.transaction.data),
      "amount" => result.outputs_amount,
      "miner_fee" => result.fee,
    }

    return response
  end # build_transaction



  # 2. Client posts complete information about signatures and an unsigned transaction
  #    to put those signatures in.
  #
  # POST /v2/transactions/sign
  # {
  #   "inputs_to_sign": [
  #     {
  #       "address": "1address1",
  #       "hash_to_sign": "0327549...",
  #       "signature": "05476282342343247432...",
  #       "public_key": "04939d3k393..."
  #     },
  #             {
  #       "address": "3address2",
  #       "hash_to_sign": "0426434...",
  #       "signatures": ["012938...", "48301203...", "933022..."],
  #       "public_keys": ["0492023023...", "0495214cd072f3, "0495f9292kd0..."]
  #     }
  #   ],
  #   "unsigned_transaction": {
  #     "hex": "0100000001ec...",
  #     "amount": 50000,
  #     "miner_fee": 10000
  #   }
  # }
  #
  # Response: info about the signed transaction.
  # {
  #   "signed_transaction": {
  #     "hex": "0100000001ec...",
  #     "amount": 50000,
  #     "miner_fee": 10000
  #   }
  # }
  def sign_transaction(dict)

    if !dict["unsigned_transaction"].is_a?(Hash) ||
       !dict["unsigned_transaction"]["hex"].is_a?(String)
      return {
        "message" => "Unsigned transaction is required.",
        "code" => "CH?08",
      }
    end

    tx = BTC::Transaction.with_hex(dict["unsigned_transaction"]["hex"])

    if !tx
      return {
        "message" => "Invalid transaction encoding.",
        "code" => "CH?09",
      }
    end

    # inputs could be empty if tx is fully signed by the client.
    inputs_to_sign = dict["inputs_to_sign"] || []

    if !inputs_to_sign.is_a?(Array)
      return {
        "message" => "Inputs to sign must be an array of dictionaries.",
        "code" => "CH?10",
      }
    end

    # Either they give us no signed inputs or they give us all of them.
    if inputs_to_sign.size != 0 && inputs_to_sign.size != tx.inputs.size
      return {
        "message" => "Invalid number of inputs.",
        "code" => "CH?11",
      }
    end

    inputs_to_sign.each_with_index do |input_dict, i|

      # BTC::TransactionBuilder always puts utxo script in the signature_script.
      output_script = tx.inputs[i].signature_script

      # a. Check if we have the complete signature_script already for arbitrary script
      if (hex_script = input_dict["signature_script"]).is_a?(String)
        sig_script = Script.with_data(BTC::Data.data_from_hex(hex_script))
        if !sig_script
          return {
            "message" => "Invalid signature_script encoding for input #{i}",
            "code" => "CH?12",
          }
        end
        tx.inputs[i].signature_script = sig_script

      # b. Check if we have a single key and a single signature
      elsif input_dict["signature"]
        sig = BTC::Data.data_from_hex(input_dict["signature"])
        if err = check_raw_signature(sig)
          return err
        end

        # If it's an old-school '<pubkey> OP_CHECKSIG' script, we only need a signature.
        # And a public key could be either compressed or non-compressed, does not matter.
        if output_script.public_key_script?
          pk = BTC::Key.with_public_key(output_script.to_a.first)
          if !pk
            return {
              "message" => "Output script does not have a valid public key for input #{i}.",
              "code" => "CH?14",
            }
          end

          if !pk.verify_ecdsa_signature(sig, tx.signature_hash(input_index: i, output_script: output_script, hash_type: BTC::SIGHASH_ALL))
            return invalid_sig_response
          end

          tx.inputs[i].signature_script = BTC::Script.new << pushdata_sig(sig)

        # Most popular "pay to key hash" script (aka "pay to address")
        # Signer must provide a pubkey as well and that pubkey must hash into address (so compressed/uncompressed matters)
        # Script is "OP_DUP OP_HASH160 <20-byte hash> OP_EQUALVERIFY OP_CHECKSIG"
        elsif output_script.public_key_hash_script?

          address_hash = output_script.to_a[2]

          pk = BTC::Data.data_from_hex(input_dict["public_key"])

          if !pk
            return {
              "message" => "Public key is missing for input #{i}.",
              "code" => "CH?15",
            }
          end

          # Check if pubkey is itself valid and canonical
          if err = check_raw_pubkey(pk)
            return err
          end

          # Check if pubkey is hashed to this address
          if BTC::Data.hash160(pk) != address_hash
            return invalid_sig_response("Invalid pubkey (does not match address, check if it's compressed or uncompressed)")
          end

          tx.inputs[i].signature_script = BTC::Script.new << pushdata_sig(sig) << pk

        else
          return {
            "message" => "Unsupported output script: #{output_script.to_s} for input #{i}",
            "code" => "CH?16",
          }
        end # types of single-key scripts

      # c. Check if we have a multisig signatures and pubkeys.
      #    This applies to both P2SH and raw non-P2SH multisig outputs.
      elsif input_dict["signatures"].is_a?(Array)

        # First, check if all signatures are kosher.
        sigs = input_dict["signatures"].map{|s| BTC::Data.data_from_hex(s) }

        sigs.each do |sig|
          if err = check_raw_signature(sig)
            return err
          end
        end

        if sigs.size == 0
          return invalid_sig_response("No signatures provided for input #{i}.")
        end

        # Check if it's a simple multisig output for which we need to provide the signatures.
        # script = "<M> <pubkey1> ... <pubkeyN> <N> OP_CHECKMULTISIG"
        if output_script.multisig_script?
          m = output_script.multisig_signatures_required
          if sigs.size != m
            return invalid_sig_response("Invalid number of signatures (#{m} expected, #{sigs.size} given) for input #{i}")
          end

          # TODO: verify signatures for each subset of the pubkeys when we have time.

          tx.inputs[i].signature_script = BTC::Script.new << OP_0 << sigs.map{|s| pushdata_sig(s) }

        # Check if it's P2SH script and we assume it is a vanilla multisig.
        elsif output_script.script_hash_script?

          # We need pubkeys
          hex_pks = input_dict["public_keys"]
          if !hex_pks.is_a?(Array) || hex_pks.size == 0
            return invalid_sig_response("No public keys provided for input #{i}.")
          end

          # Hex -> binary
          pks = hex_pks.map{|hexpk| BTC::Data.data_from_hex(hexpk) }

          # Check if every pubkey is kosher.
          pks.each do |pk|
            if err = check_raw_pubkey(pk)
              return err
            end
          end

          # Now compose a multisig script
          multisig_script = BTC::Script.multisig_script(public_keys: pks, signatures_required: sigs.size)

          # Check that it hashes to P2SH hash.
          if !(multisig_script.p2sh_script == output_script)
            return invalid_sig_response("Multisig script with provided signatures and pubkeys does not match P2SH hash (check if pubkeys are compressed/uncompressed correctly).")
          end

          # TODO: verify the signatures against each subset of pubkey when we have time.

          # Compose the final input. (Sigs and multisig serialized pushdata to satisfy P2SH.)
          tx.inputs[i].signature_script = BTC::Script.new << OP_0 << sigs.map{|s| pushdata_sig(s) } << multisig_script.data

        # Some other kind of script? We don't support it.
        else
          return {
            "message" => "Unsupported output script: #{output_script.to_s} for input #{i}",
            "code" => "CH?16",
          }
        end # types of multisig scripts

      else
        return {
          "message" => "Unsupported signature info for input #{i}",
          "code" => "CH?17",
        }
      end # types of signatures
    end # inputs_to_sign.each_with_index

    # Simply take what we've got and replace transaction
    # (so we don't need to re-fetch inputs and compute amounts and fees)
    response = {
      "signed_transaction" => dict["unsigned_transaction"].dup
    }

    response["signed_transaction"]["hex"] = tx.to_hex

    return response

  end # sign_transaction



  private

  # Signature with hashtype appended as needed for signature_script
  def pushdata_sig(raw_sig)
    (raw_sig.to_s + WireFormat.encode_uint8(BTC::SIGHASH_ALL))
  end

  # Returns error dict if sig (without hashtype byte) is invalid.
  # Returns nil if sig is valid.
  def check_raw_signature(sig)
    BTC::Diagnostics.current.last_message = nil
    if !BTC::Key.validate_script_signature(pushdata_sig(sig))
      return invalid_sig_response(BTC::Diagnostics.current.last_message)
    end
    return nil
  end

  # Returns error dict if pubkey is invalid or not canonical.
  # Returns nil if pubkey is valid.
  def check_raw_pubkey(pk)
    BTC::Diagnostics.current.last_message = nil
    if !BTC::Key.validate_public_key(pk)
      return invalid_sig_response(BTC::Diagnostics.current.last_message || "Invalid public key.")
    end
    return nil
  end

  def invalid_sig_response(msg = nil)
    return {
      "message" => msg || "Invalid signature.",
      "code" => "CH?13",
    }
  end

end # TransactionBuilderAPI