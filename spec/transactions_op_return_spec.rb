require_relative 'spec_helper'

describe "Transaction OP_RETURN API" do

  before do
    @client = Chain::Client.new(api_key_id: "2277e102b5d28a90700ff3062a282228", api_key_secret: "5612b8724d3b3cbfb580a2c3e5b072a7")
    @client.network = Chain::NETWORK_MAINNET
  end

  it "should get OP_RETURN info about one transaction" do

    # {
    #     "transaction_hash": "4a7d62a4a5cc912605c46c6a6ef6c4af451255a453e6cbf2b1022766c331f803",
    #     "hex": "436861696e2e636f6d202d2054686520426c6f636b20436861696e20415049",
    #     "text": "Chain.com - The Block Chain API",
    #     "receiver_addresses": ["1Bj5UVzWQ84iBCUiy5eQ1NEfWfJ4a3yKG1"],
    #     "sender_addresses": ["1Bj5UVzWQ84iBCUiy5eQ1NEfWfJ4a3yKG1"]
    # }
    info = @client.get_transaction_op_return('4a7d62a4a5cc912605c46c6a6ef6c4af451255a453e6cbf2b1022766c331f803')
    expect(info).to be_a_kind_of(Chain::OpReturnInfo)
    expect(info.transaction_hash).to eq(BTC.hash_from_id("4a7d62a4a5cc912605c46c6a6ef6c4af451255a453e6cbf2b1022766c331f803"))
    expect(info.transaction_id).to eq("4a7d62a4a5cc912605c46c6a6ef6c4af451255a453e6cbf2b1022766c331f803")
    expect(info.data).to be_a_kind_of(String)
    expect(info.data).to eq("Chain.com - The Block Chain API")
    expect(info.text).to eq("Chain.com - The Block Chain API")
    expect(info.receiver_addresses).to eq [BTC::Address.with_string('1Bj5UVzWQ84iBCUiy5eQ1NEfWfJ4a3yKG1')]
    expect(info.sender_addresses).to   eq [BTC::Address.with_string('1Bj5UVzWQ84iBCUiy5eQ1NEfWfJ4a3yKG1')]
    info.receiver_addresses.each do |addr|
      expect(addr).to be_a_kind_of(BTC::Address)
    end
  end
end