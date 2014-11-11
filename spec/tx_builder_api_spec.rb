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

    #puts result.inspect

    expect(result["inputs_to_sign"].class).to eq(Array)
    expect(result["unsigned_transaction"].class).to eq(::Hash)

    tx = BTC::Transaction.with_hex(result["unsigned_transaction"]["hex"])

    expect(tx.inputs.size).to eq(result["inputs_to_sign"].size)

  end

end