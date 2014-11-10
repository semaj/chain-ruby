require_relative 'spec_helper'

describe "Transaction broadcast API" do

  before do
    @client = Chain::Client.new(api_key_id: "2277e102b5d28a90700ff3062a282228", api_key_secret: "5612b8724d3b3cbfb580a2c3e5b072a7")
    @client.network = Chain::NETWORK_TESTNET
  end

  it "should broadcast a valid transaction" do

    # Note: this key has some testcoins to be spendable each time this test runs.
    # Please do not remove coins from here. Thank you!
    key = BTC::Key.with_private_key(BTC::Data.data_from_hex("c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a"), public_key_compressed: true)
    address = key.testnet_address
    expect(address.to_s).to eq("mrdwvWkma2D6n9mGsbtkazedQQuoksnqJV")

    # 1. Fetch unspents for this key
    utxos = @client.get_address_unspents(address)
    fee = 1
    utxos = utxos.find_all{|utxo| utxo.value >= 2*fee }

    if utxos.size > 0

      # 2. Compose tx spending one of the unspents to the same address with some fees.
      utxo = utxos.first
      tx = BTC::Transaction.new
      tx.add_input(BTC::TransactionInput.new(
        previous_hash: utxo.transaction_hash,
        previous_index: utxo.index,
        signature_script: utxo.script
      ))
      tx.add_output(BTC::TransactionOutput.new(value: utxo.value - fee, script: address.script))

      # 3. Sign the transaction
      sighash = tx.signature_hash(input_index: 0, output_script: tx.outputs.first.script, hash_type: BTC::SIGHASH_ALL)
      tx.inputs.first.signature_script = (BTC::Script.new <<
        (key.ecdsa_signature(sighash) + BTC::WireFormat.encode_uint8(BTC::SIGHASH_ALL)) <<
        key.public_key)

      # 4. Broadcast it. Succesful broadcast returns tx id.
      expect(@client.send_transaction(tx)).to eq(tx.transaction_id)
    else
      puts "WARNING: not enough funds on #{address.to_s} to run broadcast spec. Please send some coins there using http://tpfaucet.appspot.com/."
      # Note: we are not failing this spec so we don't get DoS on our build integration tests.
    end
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