require 'spec_helper'

describe Chain::Transaction do

  describe "A simple transaction" do
    it "should be valid" do
      expect do
        Chain::Transaction.new(
          inputs: [],
          outputs: {},
          change_address: 'a',
          fee: 0
        )
      end.to raise_error(Chain::Transaction::MissingInputsError)
    end
  end

end
