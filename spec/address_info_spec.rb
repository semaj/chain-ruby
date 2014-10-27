require_relative 'spec_helper'

describe "Addresses API" do

  before do
    @client = Chain::Client.new(api_key_id: "2277e102b5d28a90700ff3062a282228", api_key_secret: "5612b8724d3b3cbfb580a2c3e5b072a7")
    @client.network = Chain::NETWORK_MAINNET
  end

  it "should get info about one address" do
    # Both types are supported: String and BTC::Address
    ["17x23dNjXJLzGMev6R63uyRhMWP1VHawKc", BTC::Address.with_string("17x23dNjXJLzGMev6R63uyRhMWP1VHawKc") ].each do |addr|
      info = @client.get_address(addr)
      expect(info).to be_a_kind_of(Chain::AddressInfo)
      expect(info.address).to be_a_kind_of(BTC::PublicKeyAddress)
      expect(info.address.to_s).to eq("17x23dNjXJLzGMev6R63uyRhMWP1VHawKc")
      expect(info.balance).to eq(5000000000)
      expect(info.received).to eq(5000000000)
      expect(info.sent).to eq(0)
      expect(info.unconfirmed_received).to eq(0)
      expect(info.unconfirmed_sent).to eq(0)
      expect(info.unconfirmed_balance).to eq(0)
    end
  end

  it "should get info about several addresses" do
    infos = @client.get_addresses(["17x23dNjXJLzGMev6R63uyRhMWP1VHawKc","1EX1E9n3bPA1zGKDV5iHY2MnM7n5tDfnfH"])
    expect(infos).to be_a_kind_of(Array)
    expect(infos[0].address.to_s).to eq("17x23dNjXJLzGMev6R63uyRhMWP1VHawKc")
    expect(infos[1].address.to_s).to eq("1EX1E9n3bPA1zGKDV5iHY2MnM7n5tDfnfH")
    infos.each do |info|
      expect(info).to be_a_kind_of(Chain::AddressInfo)
      expect(info.address).to be_a_kind_of(BTC::PublicKeyAddress)
    end
  end
end