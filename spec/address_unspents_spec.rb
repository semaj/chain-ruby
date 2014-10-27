require_relative 'spec_helper'

describe "Address Unspents API" do

  before do
    @client = Chain::Client.new(api_key_id: "2277e102b5d28a90700ff3062a282228", api_key_secret: "5612b8724d3b3cbfb580a2c3e5b072a7")
    @client.network = Chain::NETWORK_MAINNET
  end

  it "should fetch unspents for a single address" do
    list = @client.get_address_unspents("1K4nPxBMy6sv7jssTvDLJWk1ADHBZEoUVb")
    expect(list.size).to eq(3)
    list = list.sort_by{|txout| txout.confirmations } # latest first
    list[0].tap do |utxo|
      expect(utxo.transaction_id).to eq("0bf0de38c26195919179f42d475beb7a6b15258c38b57236afdd60a07eddd2cc")
      expect(utxo.index).to eq(0)
      expect(utxo.confirmations).to be > 23000
      expect(utxo.script.standard_address.to_s).to eq("1K4nPxBMy6sv7jssTvDLJWk1ADHBZEoUVb")
    end
    list[1].tap do |utxo|
      expect(utxo.transaction_id).to eq("b84a66c46e24fe71f9d8ab29b06df932d77bec2cc0691799fae398a8dc9069bf")
      expect(utxo.index).to eq(1)
      expect(utxo.confirmations).to be > 23000
      expect(utxo.script.standard_address.to_s).to eq("1K4nPxBMy6sv7jssTvDLJWk1ADHBZEoUVb")
    end
    list[2].tap do |utxo|
      expect(utxo.transaction_id).to eq("5ad2913b948c883b007b1bca39322c42d60ef465b9dc39bc0a53ffe8fe3faafd")
      expect(utxo.index).to eq(0)
      expect(utxo.confirmations).to be > 23000
      expect(utxo.script.standard_address.to_s).to eq("1K4nPxBMy6sv7jssTvDLJWk1ADHBZEoUVb")
    end
  end


  it "should fetch unspents for multiple addresses" do
    list = @client.get_addresses_unspents(["1K4nPxBMy6sv7jssTvDLJWk1ADHBZEoUVb", "1EX1E9n3bPA1zGKDV5iHY2MnM7n5tDfnfH"])
    expect(list.size).to eq(4)
    list = list.sort_by{|txout| txout.confirmations } # latest first
    list[0].tap do |utxo|
      expect(utxo.transaction_id).to eq("0bf0de38c26195919179f42d475beb7a6b15258c38b57236afdd60a07eddd2cc")
      expect(utxo.index).to eq(0)
      expect(utxo.confirmations).to be > 23000
      expect(utxo.script.public_key_hash_script?).to eq(true)
      expect(utxo.script.standard_address.to_s).to eq("1K4nPxBMy6sv7jssTvDLJWk1ADHBZEoUVb")
    end
    list[1].tap do |utxo|
      expect(utxo.transaction_id).to eq("b84a66c46e24fe71f9d8ab29b06df932d77bec2cc0691799fae398a8dc9069bf")
      expect(utxo.index).to eq(1)
      expect(utxo.confirmations).to be > 23000
      expect(utxo.script.public_key_hash_script?).to eq(true)
      expect(utxo.script.standard_address.to_s).to eq("1K4nPxBMy6sv7jssTvDLJWk1ADHBZEoUVb")
    end
    list[2].tap do |utxo|
      expect(utxo.transaction_id).to eq("5ad2913b948c883b007b1bca39322c42d60ef465b9dc39bc0a53ffe8fe3faafd")
      expect(utxo.index).to eq(0)
      expect(utxo.confirmations).to be > 23000
      expect(utxo.script.public_key_hash_script?).to eq(true)
      expect(utxo.script.standard_address.to_s).to eq("1K4nPxBMy6sv7jssTvDLJWk1ADHBZEoUVb")
    end
    list[3].tap do |utxo|
      expect(utxo.transaction_id).to eq("80ec89837a388421e81d912b9e695b7920990dad85956ff5bc484ce82b19db6c")
      expect(utxo.index).to eq(0)
      expect(utxo.confirmations).to be > 326630
      expect(utxo.script.public_key_script?).to eq(true)
      expect(utxo.script.standard_address.to_s).to eq("1EX1E9n3bPA1zGKDV5iHY2MnM7n5tDfnfH")
    end

  end

end