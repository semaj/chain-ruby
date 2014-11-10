require_relative 'spec_helper'

describe "Block API" do

  before do
    @client = Chain::Client.new(api_key_id: "2277e102b5d28a90700ff3062a282228", api_key_secret: "5612b8724d3b3cbfb580a2c3e5b072a7")
    @client.network = Chain::NETWORK_MAINNET
  end

  it "should get BTC::Block by its height" do
    block = @client.get_block(0)
    expect(block.height).to eq(0)
    expect(block.block_id).to eq("000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f")

    block = @client.get_block(100000)
    expect(block.height).to eq(100000)
    expect(block.block_id).to eq("000000000003ba27aa200b1cecaad478d2b00432346c3f1f3986da1afd33e506")
    expect(block.transactions.map{|tx| tx.transaction_id}).to eq(block.transaction_ids)
  end

end
