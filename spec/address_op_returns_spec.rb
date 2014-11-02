require_relative 'spec_helper'

describe "Address OP_RETURN API" do

  before do
    @client = Chain::Client.new(api_key_id: "2277e102b5d28a90700ff3062a282228", api_key_secret: "5612b8724d3b3cbfb580a2c3e5b072a7")
    @client.network = Chain::NETWORK_MAINNET
  end

  it "should get info about one address" do
    
    @client.get_address_op_returns('1Bj5UVzWQ84iBCUiy5eQ1NEfWfJ4a3yKG1').each do |info|
      expect(info).to be_a_kind_of(Chain::OpReturnInfo)
      expect(info.transaction_hash).to be_a_kind_of(String)
      expect(info.transaction_id).to be_a_kind_of(String)
      expect(info.data).to be_a_kind_of(String)
      expect(info.text).to be_a_kind_of(String)
      expect(info.sender_addresses).to be_a_kind_of(Array)
      expect(info.receiver_addresses).to be_a_kind_of(Array)
      info.sender_addresses.each do |addr|
        expect(addr).to be_a_kind_of(BTC::Address)
      end
      expect(info.receiver_addresses).to include(BTC::Address.with_string('1Bj5UVzWQ84iBCUiy5eQ1NEfWfJ4a3yKG1'))
      info.receiver_addresses.each do |addr|
        expect(addr).to be_a_kind_of(BTC::Address)
      end
    end
  end
end