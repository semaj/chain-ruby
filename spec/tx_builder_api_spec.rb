require_relative 'spec_helper'
require_relative '../lib/chain/tx_builder_api.rb'

describe "Transaction builder API" do

  before do
    @client = Chain::Client.new(api_key_id: "2277e102b5d28a90700ff3062a282228", api_key_secret: "5612b8724d3b3cbfb580a2c3e5b072a7")
    @client.network = Chain::NETWORK_TESTNET
    @builder = TransactionBuilderAPI.new
    @builder.client = @client
  end

  it "should build a simple transaction" do

    key = BTC::Key.with_private_key(BTC::Data.data_from_hex("c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a"), public_key_compressed: true)
    address = key.address(testnet: true)
    expect(address.to_s).to eq("mrdwvWkma2D6n9mGsbtkazedQQuoksnqJV")

    result = @builder.build_transaction({
        "inputs" => [
          "mrdwvWkma2D6n9mGsbtkazedQQuoksnqJV"
        ],
        "outputs" => [
          {
            "address" => "mrdwvWkma2D6n9mGsbtkazedQQuoksnqJV",
            "amount" => 1000
          },
          {
            "address" => "mrdwvWkma2D6n9mGsbtkazedQQuoksnqJV",
            "amount" => 2000
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
    # puts result.inspect

    expect(result["inputs_to_sign"].class).to eq(Array)
    expect(result["unsigned_transaction"].class).to eq(::Hash)

    tx = BTC::Transaction.with_hex(result["unsigned_transaction"]["hex"])

    expect(tx.inputs.size).to eq(result["inputs_to_sign"].size)

    # Sign the inputs & send for assembly

    request2 = result.dup
    request2["inputs_to_sign"].each do |dict|
      expect(dict["address"]).to eq("mrdwvWkma2D6n9mGsbtkazedQQuoksnqJV")
      hash = BTC::Data.data_from_hex(dict["hash_to_sign"])
      expect(hash.size).to eq(32)

      dict["signature"] = BTC::Data.hex_from_data(key.ecdsa_signature(hash))
      dict["public_key"] = BTC::Data.hex_from_data(key.public_key)
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
    puts result.inspect

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
    # puts tx.inspect

    # Broadcast for debugging
    if false
      txid =  @client.send_transaction(tx)
      puts txid.inspect
    end

  end


  it "should spend a multisig P2SH input" do

  end


end