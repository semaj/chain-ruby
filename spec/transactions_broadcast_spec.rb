require_relative 'spec_helper'

describe "Transaction broadcast API" do

  before do
    @client = Chain::Client.new(api_key_id: "2277e102b5d28a90700ff3062a282228", api_key_secret: "5612b8724d3b3cbfb580a2c3e5b072a7")
    @client.network = Chain::NETWORK_TESTNET
  end

  it "should broadcast a valid transaction" do

    # TODO: fetch unspents for some testnet address and spend them.

  end

end

describe "Transaction broadcast API" do

  before do
    @client = Chain::Client.new(api_key_id: "2277e102b5d28a90700ff3062a282228", api_key_secret: "5612b8724d3b3cbfb580a2c3e5b072a7")
    @client.network = Chain::NETWORK_MAINNET
  end

  it "should fail to broadcast an invalid transaction" do
    tx = BTC::Transaction.new
    expect(tx.transaction_id).to eq("d21633ba23f70118185227be58a63527675641ad37967e2aa461559f577aec43")
    expect do
      @client.send_transaction(tx)
    end.to raise_error(Chain::ChainBroadcastError)
  end

  it "should fail to broadcast an existing transaction" do
    tx = @client.get_transaction("0f40015ddbb8a05e26bbacfb70b6074daa1990b813ba9bc70b7ac5b0b6ee2c45")
    expect(tx.transaction_id).to eq("0f40015ddbb8a05e26bbacfb70b6074daa1990b813ba9bc70b7ac5b0b6ee2c45")
    expect do
      @client.send_transaction(tx)
    end.to raise_error(Chain::ChainBroadcastError)
  end

end