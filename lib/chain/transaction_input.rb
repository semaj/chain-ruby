# Chain-specific extensions to BTC::TransactionInput
module BTC
  BTC::TransactionInput # make sure class is loaded with its proper superclass.
  class TransactionInput
    
    # List of BTC::Address instances for each address involved in this input.
    attr_accessor :addresses
    
  end
end
