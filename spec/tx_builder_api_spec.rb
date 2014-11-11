require_relative 'spec_helper'
require_relative '../lib/chain/tx_builder_api.rb'
#require 'btcruby/extensions.rb' # to enable String#to_hex, String#from_hex

describe "Transaction builder API" do

  before do
    @client = Chain::Client.new(api_key_id: "2277e102b5d28a90700ff3062a282228", api_key_secret: "5612b8724d3b3cbfb580a2c3e5b072a7")
    @client.network = Chain::NETWORK_TESTNET
    @builder = TransactionBuilderAPI.new
    @builder.client = @client

    @key1 = BTC::Key.with_private_key(BTC::Data.data_from_hex("c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a"), public_key_compressed: true)
    expect(@key1.address(testnet: true).to_s).to eq("mrdwvWkma2D6n9mGsbtkazedQQuoksnqJV")
    @key2 = BTC::Key.with_private_key(BTC::Data.data_from_hex("c4bbcb2fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a"), public_key_compressed: true)
    expect(@key2.address(testnet: true).to_s).to eq("n3j9wYimz7nuS4sDkUxDymL9w5SKUgM2wM")
    @key3 = BTC::Key.with_private_key(BTC::Data.data_from_hex("c4bbcb3fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a"), public_key_compressed: true)
    expect(@key3.address(testnet: true).to_s).to eq("mfpP1kw9VB4ADAFDnt3wiUkqfGda9fB8QA")
  end

  it "should build a single-key transaction" do

    key = @key1
    address = @key1.address(testnet: true) # mrdwvWkma2D6n9mGsbtkazedQQuoksnqJV

    multisig_script = BTC::Script.multisig_script(public_keys: [@key1.public_key, @key2.public_key, @key3.public_key], signatures_required: 2)
    p2shaddr = multisig_script.p2sh_script.standard_address(testnet: true).to_s

    expect(BTC::Data.hex_from_data(multisig_script.data)).to eq("52210378d430274f8c5ec1321338151e9f27f4c676a008bdf8638d07c0b6be9ab35c7121026a361b855808aeba02d3143b3ec884f709b24d5391c515bd4eafd69d1afae337210355e9d91d63acb15a75c1a9205fc4c0a0878778e08e0a9ca22adb0c2c33fa880153ae")
    expect(p2shaddr).to eq("2NDdMCpA9to3ayTkXJQ3DvfKuSxjyRtFG5S")

    result = @builder.build_transaction({
        "inputs" => [
          "mrdwvWkma2D6n9mGsbtkazedQQuoksnqJV"
        ],
        "outputs" => [
          {
            "address" => "mrdwvWkma2D6n9mGsbtkazedQQuoksnqJV",
            "amount" => 2000
          },
          {
            "address" => p2shaddr, # 2NDdMCpA9to3ayTkXJQ3DvfKuSxjyRtFG5S (P2SH 2-of-3 multisig)
            "amount" => 1000
          },
        ],
        "change_address" => "mrdwvWkma2D6n9mGsbtkazedQQuoksnqJV",
        "miner_fee_rate" => 100,
        "min_confirmations" => 0
      })

    # {"inputs_to_sign"=>[
    #   {"address"=>"mrdwvWkma2D6n9mGsbtkazedQQuoksnqJV",
    #     "hash_to_sign"=>"68de81e49eee282ec147baccbb596d1e430c9285fb4db101d27234107554358d",
    #     "signature"=>"!---insert-signature---!",
    #     "public_key"=>"!---insert-public-key---!"}
    #   ],
    #   "unsigned_transaction"=>{
    #     "hex"=>"0100000001539dd2e347a3219277bd6d26ef169c8ca3e9d9a7a841880d4f5f4bd6c5fd1479000000001976a91479fbfc3f34e7745860d76137da68f362380c606c88acffffffff03e8030000000000001976a91479fbfc3f34e7745860d76137da68f362380c606c88acd0070000000000001976a91479fbfc3f34e7745860d76137da68f362380c606c88ace4af7334000000001976a91479fbfc3f34e7745860d76137da68f362380c606c88ac00000000",
    #     "amount"=>879999900,
    #     "miner_fee"=>100
    #   }
    # }
    #puts result.inspect

    expect(result["inputs_to_sign"].class).to eq(Array)
    expect(result["unsigned_transaction"].class).to eq(::Hash)

    tx = BTC::Transaction.with_hex(result["unsigned_transaction"]["hex"])

    expect(tx.inputs.size).to eq(result["inputs_to_sign"].size)

    # Sign the inputs & send for assembly

    request2 = result.dup
    request2["inputs_to_sign"].each_with_index do |dict, input_i|
      expect(dict["address"]).to eq("mrdwvWkma2D6n9mGsbtkazedQQuoksnqJV")
      hash = BTC::Data.data_from_hex(dict["hash_to_sign"])
      expect(hash.size).to eq(32)

      expected_hash = tx.signature_hash(input_index: input_i,
                                        output_script: tx.inputs[input_i].signature_script,
                                        hash_type: BTC::SIGHASH_ALL)

      expect(hash).to eq(expected_hash)

      sig = @key1.ecdsa_signature(hash)

      #puts "SIGNING: #{@key1.public_key.to_hex} + #{hash.to_hex} => #{sig.to_hex}"
      expect(@key1.verify_ecdsa_signature(sig, hash)).to eq(true)

      dict["signature"] = BTC::Data.hex_from_data(sig)
      dict["public_key"] = BTC::Data.hex_from_data(@key1.public_key)
    end

    # Send for composing a final signed transaction
    # {"inputs_to_sign"=>[
    #   {
    #     "address"=>"mrdwvWkma2D6n9mGsbtkazedQQuoksnqJV",
    #     "hash_to_sign"=>"68de81e49eee282ec147baccbb596d1e430c9285fb4db101d27234107554358d",
    #     "signature"=>"304402204d0b66152b38b4679e5f2c1410d99ffc20e18777e6996ae848aca42c1087c1fa02203c3ac4952e424c7bcc77f1892007c98db8a0b5e5908423b1ad44f38c71fc9d14",
    #     "public_key"=>"0378d430274f8c5ec1321338151e9f27f4c676a008bdf8638d07c0b6be9ab35c71"
    #   }],
    #   "unsigned_transaction"=>{
    #     "hex"=>"0100000001539dd2e347a3219277bd6d26ef169c8ca3e9d9a7a841880d4f5f4bd6c5fd1479000000001976a91479fbfc3f34e7745860d76137da68f362380c606c88acffffffff03e8030000000000001976a91479fbfc3f34e7745860d76137da68f362380c606c88acd0070000000000001976a91479fbfc3f34e7745860d76137da68f362380c606c88ace4af7334000000001976a91479fbfc3f34e7745860d76137da68f362380c606c88ac00000000",
    #     "amount"=>879999900,
    #     "miner_fee"=>100
    #   }
    # }
    # puts result.inspect

    result = @builder.assemble_transaction(request2)

    # {"signed_transaction"=>
    #   {"hex"=>"0100000001539dd2e347a3219277bd6d26ef169c8ca3e9d9a7a841880d4f5f4bd6c5fd1479000000006a47304402204d0b66152b38b4679e5f2c1410d99ffc20e18777e6996ae848aca42c1087c1fa02203c3ac4952e424c7bcc77f1892007c98db8a0b5e5908423b1ad44f38c71fc9d1401210378d430274f8c5ec1321338151e9f27f4c676a008bdf8638d07c0b6be9ab35c71ffffffff03e8030000000000001976a91479fbfc3f34e7745860d76137da68f362380c606c88acd0070000000000001976a91479fbfc3f34e7745860d76137da68f362380c606c88ace4af7334000000001976a91479fbfc3f34e7745860d76137da68f362380c606c88ac00000000",
    #    "amount"=>879999900,
    #    "miner_fee"=>100}}
    # puts result.inspect

    expect(result["signed_transaction"].class).to eq(::Hash)

    tx = BTC::Transaction.with_hex(result["signed_transaction"]["hex"])

    # #<BTC::Transaction:119e50c547b8e3b008e64616d9242c8de29b5e1611c3479916cb5b54980c845c v1
    #   inputs:[
    #     #<BTC::TransactionInput prev:539dd2e347[0] script:"304402204d0b66152b38b4679e5f2c1410d99ffc20e18777e6996ae848aca42c1087c1fa02203c3ac4952e424c7bcc77f1892007c98db8a0b5e5908423b1ad44f38c71fc9d1401 0378d430274f8c5ec1321338151e9f27f4c676a008bdf8638d07c0b6be9ab35c71">
    #     ]
    #   outputs:[
    #     #<BTC::TransactionOutput value:0.00001000 script:"OP_DUP OP_HASH160 79fbfc3f34e7745860d76137da68f362380c606c OP_EQUALVERIFY OP_CHECKSIG">,
    #     #<BTC::TransactionOutput value:0.00002000 script:"OP_DUP OP_HASH160 79fbfc3f34e7745860d76137da68f362380c606c OP_EQUALVERIFY OP_CHECKSIG">,
    #     #<BTC::TransactionOutput value:8.79996900 script:"OP_DUP OP_HASH160 79fbfc3f34e7745860d76137da68f362380c606c OP_EQUALVERIFY OP_CHECKSIG">
    #   ]>
    #puts tx.inspect
    #puts tx.to_hex

    # Broadcast for debugging
    if false
      txid =  @client.send_transaction(tx)
      puts txid.inspect
    end

  end


  it "should spend a multisig P2SH input" do

    key = @key1
    address = @key1.address(testnet: true) # mrdwvWkma2D6n9mGsbtkazedQQuoksnqJV

    multisig_script = BTC::Script.multisig_script(public_keys: [@key1.public_key, @key2.public_key, @key3.public_key], signatures_required: 2)
    p2shaddr = multisig_script.p2sh_script.standard_address(testnet: true).to_s

    result = @builder.build_transaction({
        "inputs" => [
          "2NDdMCpA9to3ayTkXJQ3DvfKuSxjyRtFG5S"
        ],
        "p2sh" => {
          "2NDdMCpA9to3ayTkXJQ3DvfKuSxjyRtFG5S" => BTC::Data.hex_from_data(multisig_script.data)
        },
        "outputs" => [
          {
            "address" => p2shaddr,
            "amount" => 1000
          },
          {
            "address" => p2shaddr, # 2NDdMCpA9to3ayTkXJQ3DvfKuSxjyRtFG5S (P2SH 2-of-3 multisig)
            "amount" => 1000
          },
        ],
        "change_address" => p2shaddr,
        "miner_fee_rate" => 10,
        "min_confirmations" => 0
      })

    #puts result.inspect

    expect(result["inputs_to_sign"].class).to eq(Array)
    expect(result["unsigned_transaction"].class).to eq(::Hash)

    tx = BTC::Transaction.with_hex(result["unsigned_transaction"]["hex"])

    expect(tx.inputs.size).to eq(result["inputs_to_sign"].size)

    # Sign the inputs & send for assembly

    request2 = result.dup
    request2["inputs_to_sign"] = []
    result["inputs_to_sign"].each_with_index do |dict, input_i|
      expect(dict["address"]).to eq("2NDdMCpA9to3ayTkXJQ3DvfKuSxjyRtFG5S")
      hash = BTC::Data.data_from_hex(dict["hash_to_sign"])
      expect(hash.size).to eq(32)

      expected_hash = tx.signature_hash(input_index: input_i,
                                        output_script: multisig_script,
                                        hash_type: BTC::SIGHASH_ALL)

      expect(hash).to eq(expected_hash)

      sig1 = @key1.ecdsa_signature(hash)
      expect(@key1.verify_ecdsa_signature(sig1, hash)).to eq(true)

      sig2 = @key2.ecdsa_signature(hash)
      expect(@key2.verify_ecdsa_signature(sig2, hash)).to eq(true)

      sig3 = @key3.ecdsa_signature(hash)
      expect(@key3.verify_ecdsa_signature(sig3, hash)).to eq(true)

      dict2 = {}
      dict2["address"] = dict["address"]
      dict2["hash_to_sign"] = dict["hash_to_sign"]
      dict2["signatures"] = [sig1, sig3].map{|s| BTC::Data.hex_from_data(s) }
      dict2["public_keys"] = [@key1.public_key, @key2.public_key, @key3.public_key].map{|pk| BTC::Data.hex_from_data(pk) }
      request2["inputs_to_sign"] << dict2
    end

    # Send for composing a final signed transaction

    # puts "---- request2 ----"
    # puts request2.inspect
    # puts "------------------"

    result = @builder.assemble_transaction(request2)

    # {"signed_transaction"=>
    #  {"hex"=>"0100000002ea3bf1cf426ef6aaa45bbba62406e864ea517843ec9c152bbc36ff3ae4e9baef01000000fc0047304402207d5b37f1606570ef7adc324e57d63800bbb0ff4c72dcd9e85fa20ff9b6360d5c02201e149735c341ed5e390ed7770619108ca74ed6ba8edd26ec7d9eb28fe5ae596d01473044022068dae89f2de3891c12995ec8830c8585fa6487484a34fc00323923c28425344002201112cac760ea3332592d27cf73242f5bbde971eba955780124f3ecbe22cc058f014c6952210378d430274f8c5ec1321338151e9f27f4c676a008bdf8638d07c0b6be9ab35c7121026a361b855808aeba02d3143b3ec884f709b24d5391c515bd4eafd69d1afae337210355e9d91d63acb15a75c1a9205fc4c0a0878778e08e0a9ca22adb0c2c33fa880153aeffffffffc0901b75383562bd306299186beb30e72ab07a04ccd5e2924d59d87f532eca6302000000fdfd0000483045022100cceeeb4294048ad5bd21dba0909396bd30f4911d1700e2a615da3cee5f1a819f02203896c9c15d6ae3e1d37ba6c677e52f9f88684aef1926ed8aada66c5a326d918801473044022035ccd3e11e51de873cf69ef3f57a91edea5ca774f5a399d1cdfd84eca8a171cd0220561649664f028260cc3dcf2121e1d5c2871dc72390ace4a881a41ca192d32cea014c6952210378d430274f8c5ec1321338151e9f27f4c676a008bdf8638d07c0b6be9ab35c7121026a361b855808aeba02d3143b3ec884f709b24d5391c515bd4eafd69d1afae337210355e9d91d63acb15a75c1a9205fc4c0a0878778e08e0a9ca22adb0c2c33fa880153aeffffffff03e80300000000000017a914df91b0c30b7d6ec20c50e066c07add242dcfcc1d87e80300000000000017a914df91b0c30b7d6ec20c50e066c07add242dcfcc1d87bc0700000000000017a914df91b0c30b7d6ec20c50e066c07add242dcfcc1d8700000000",
    #   "amount"=>3980, "miner_fee"=>10}}
    #puts result.inspect

    expect(result["signed_transaction"].class).to eq(::Hash)

    tx = BTC::Transaction.with_hex(result["signed_transaction"]["hex"])

    # puts tx.inspect

    # Broadcast for debugging
    if false
      txid =  @client.send_transaction(tx)
      puts txid.inspect
    end

  end


end