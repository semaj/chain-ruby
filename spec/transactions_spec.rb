require_relative 'spec_helper'

describe "Transactions API" do

  before do
    @client = Chain::Client.new(api_key_id: "2277e102b5d28a90700ff3062a282228", api_key_secret: "5612b8724d3b3cbfb580a2c3e5b072a7")
    @client.network = Chain::NETWORK_MAINNET
  end

  it "should get info about one transaction" do
    tx = @client.get_transaction('0f40015ddbb8a05e26bbacfb70b6074daa1990b813ba9bc70b7ac5b0b6ee2c45')
    expect(tx.block_hash).to eq(BTC::Transaction.hash_from_id("0000000000000000284bc285e23f970189d048ff38c030aa51007e2a8c2af2f0"))
    expect(tx.block_height).to eq 305188
    expect(tx.block_time.month).to eq 6
    expect(tx.chain_received_at.month).to eq 6
    expect(tx.inputs.size).to eq 3
    tx.inputs.each do |txin|
      expect(txin.value).to be > 0
      txin.addresses.each do |inaddr|
        expect(inaddr).to be_a_kind_of(BTC::Address)
      end
      #expect(txin.addresses.map{|a|a.to_s}).to eq ["3L7dKYQGNoZub928CJ8NC2WfrM8U8GGBjr"]
    end
    expect(tx.outputs.size).to eq 2
    expect(tx.inputs_amount).to eq(38340652 + 52900438 + 100240048)
    expect(tx.fee).to eq(0)
  end
end