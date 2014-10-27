require_relative 'spec_helper'

describe "Address Transactions API" do

  before do
    @client = Chain::Client.new(key_id: "2277e102b5d28a90700ff3062a282228", key_secret: "5612b8724d3b3cbfb580a2c3e5b072a7")
    @client.network = Chain::NETWORK_MAINNET
  end

  it "should fetch transactions for a single address" do
    txs = @client.get_address_transactions("1K4nPxBMy6sv7jssTvDLJWk1ADHBZEoUVb", limit: 2)
    expect(txs.size).to eq(2)
    expect(txs[0].confirmations).to be < txs[1].confirmations

    txs[0].tap do |tx|
      expect(tx.block_hash).to eq(BTC::Transaction.hash_from_id("00000000000000001ea5471a4edc67380f114c6cad06bfd59ac6508f90e8b252"))
      expect(tx.block_height).to eq 303404
      expect(tx.block_time.month).to eq 5
      expect(tx.chain_received_at.month).to eq 6
      expect(tx.inputs.size).to eq 1
      expect(tx.outputs.size).to eq 1
      expect(tx.inputs_amount).to eq(290000 + 10000)
      expect(tx.fee).to eq(10000)
    end

    txs[1].tap do |tx|
      expect(tx.block_hash).to eq(BTC::Transaction.hash_from_id("0000000000000000577344f05b6ea721b95fa629e0c3b16cdd929cbdf20f862f"))
      expect(tx.block_height).to eq 303402
      expect(tx.block_time.month).to eq 5
      expect(tx.chain_received_at.month).to eq 6
      expect(tx.inputs.size).to eq 2
      expect(tx.outputs.size).to eq 2
      expect(tx.inputs_amount).to eq(332000 + 10000)
      expect(tx.fee).to eq(10000)
    end
  end

end