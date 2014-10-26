require_relative 'spec_helper'

describe "Chain library" do
  
  it "should have rspec set up" do
    expect(1).to equal(1)
  end
  
  it "should have BTC Ruby included" do
    BTC::Address
    BTC::Key
    BTC::Keychain
    BTC::Transaction
  end
  
  it ""
  
end
