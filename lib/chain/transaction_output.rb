# Chain-specific extensions to BTC::TransactionOutput
module BTC
  BTC::TransactionOutput # make sure class is loaded with its proper superclass.
  class TransactionOutput
    
    # List of BTC::Address instances for each address involved in this output.
    attr_accessor :addresses
    
  end
end
