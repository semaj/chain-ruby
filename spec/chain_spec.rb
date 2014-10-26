require_relative 'spec_helper'

describe "Chain library" do

  it "should have RSpec working" do
    expect(1).to eq(1)
  end

  it "should have BTCRuby included" do
    BTC::Address
    BTC::Key
    BTC::Keychain
    BTC::Transaction
  end

  it "should be configurable with key id and secret" do
    c = Chain::Client.new(key_id: "2277e102b5d28a90700ff3062a282228", key_secret: "5612b8724d3b3cbfb580a2c3e5b072a7")
    expect(c.key_id).to eq("2277e102b5d28a90700ff3062a282228")
    expect(c.key_secret).to eq("5612b8724d3b3cbfb580a2c3e5b072a7")
    expect(c.url.to_s).to eq(Chain::CHAIN_URL)
    expect(c.network).to eq(Chain::NETWORK_MAINNET)
    c.network = Chain::NETWORK_TESTNET
    expect(c.network).to eq(Chain::NETWORK_TESTNET)
  end

  it "should support default client" do
    c = Chain.default_client
    expect(c.key_id).to eq(Chain::GUEST_KEY_ID)
    expect(c.key_secret).to eq(nil)
    expect(c.network).to eq(Chain::NETWORK_MAINNET)
  end

  it "should support default client via Chain instance" do
    c = Chain.default_client
    expect(Chain.url).to eq(c.url)
    expect(Chain.key_id).to eq(c.key_id)
    expect(Chain.key_secret).to eq(c.key_secret)
    expect(Chain.network).to eq(Chain::NETWORK_MAINNET)
  end

end
