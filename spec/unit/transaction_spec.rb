require 'spec_helper'

describe Chain::Transaction do

  describe "change" do
    it "should consider unspents, outputs and a fee" do
      expect(Chain).
      to receive(:get_addresses_unspents).
      and_return([Fixtures['get_addresses_unspents']])

      txn = Chain::Transaction.new(
        inputs: ['cVdtEyijQXFx7bmwrBMrWVbqpg8VWXsGtrUYtZR6fNZ6r4cRnRT5'],
        outputs: {
          'mxxdfxLaFGePNfFJQiVkyLix3ZAjY5cKQd' => 100,
          'mxxdfxLaFGePNfFJQiVkyLix3ZAjY4cKQd' => 100
        },
        change_address: 'mxxdfxLaFGePNfFJQiVkyLix3ZAjY5cKQd',
        fee: 0
      )
      expect(txn.change).to equal(9800)
    end
  end

  describe "fee" do

    it "uses initialized value" do
      txn = Chain::Transaction.new(
        inputs: [Fixtures['testnet_address']['private']],
        outputs: {},
        fee: 9
      )
      expect(txn.fee).to eq(9)
    end

    it "uses default value" do
      txn = Chain::Transaction.new(
        inputs: [Fixtures['testnet_address']['private']],
        outputs: {}
      )
      expect(txn.fee).to eq(Chain::Transaction::DEFAULT_FEE)
    end

  end

  describe "change_address" do

    it "uses the first address in the list of inputs when not specified" do
      txn = Chain::Transaction.new(
        inputs: ['cVdtEyijQXFx7bmwrBMrWVbqpg8VWXsGtrUYtZR6fNZ6r4cRnRT5'],
        outputs: {}
      )
      expect(txn.change_address).to eq('mxxdfxLaFGePNfFJQiVkyLix3ZAjY5cKQd')
    end

    it "uses the specified address" do
      txn = Chain::Transaction.new(
        inputs: ['cTph6fWJeBsPUV74kd314MTKzXJttk1ByzYor5yCPEDNvyiPbw3B'],
        outputs: {},
        change_address: 'mxxdfxLaFGePNfFJQiVkyLix3ZAjY5cKQd'
      )
      expect(txn.change_address).to eq('mxxdfxLaFGePNfFJQiVkyLix3ZAjY5cKQd')
    end

  end

end
