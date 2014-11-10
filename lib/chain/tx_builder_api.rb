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
  #   "required_signatures": [
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
    txindex = 0
    response["required_signatures"] = tx.inputs.map do |txin|
      utxo = txin.transaction_output
      d = {
        "address"      => utxo.script.standard_address(testnet: !change_address.mainnet?).to_s,
        "hash_to_sign" => BTC::Data.hex_from_data(tx.signature_hash(input_index: txindex,
                                                                    output_script: utxo.script,
                                                                    hash_type: BTC::SIGHASH_ALL)),
      }
      if txindex == 0
        d["signature"] = "!---insert-signature---!"
        d["public_key"] = "!---insert-public-key---!"
      else
        d["signatures"] = ["!---insert-first-signature---!", "..."]
        d["public_keys"] = ["!---insert-first-public-key---!", "..."]
      end
      txindex += 1
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
  #   "required_signatures": [
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
  # Response: info about the signed transaction. It is broadcasted right away.
  # {
  #   "signed_transaction": {
  #     "hex": "0100000001ec...",
  #     "amount": 50000,
  #     "miner_fee": 10000
  #   }
  # }
  def sign_transaction(dict)

  end

end # TransactionBuilderAPI