require 'spec_helper'

describe Chain::Transaction do

  describe "Calculating change." do
    it "should consider unspents, outputs and a fee" do
      expect(Chain).to receive(:get_addresses_unspents).and_return([{
        "transaction_hash" => "0bf0de38c26195919179f42d475beb7a6b15258c38b57236afdd60a07eddd2cc",
        "output_index" => 0,
        "value" => 10000,
        "addresses" => [
            "1K4nPxBMy6sv7jssTvDLJWk1ADHBZEoUVb"
        ],
        "script" => "OP_DUP OP_HASH160 c629680b8d13ca7a4b7d196360186d05658da6db OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex" => "76a914c629680b8d13ca7a4b7d196360186d05658da6db88ac",
        "script_type" => "pubkeyhash",
        "required_signatures" =>  1,
        "spent" => false,
        "confirmations" => 8758
      }])

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

  describe "Change address" do
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
