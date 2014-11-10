require 'btcruby'
module Chain
  # Chain::TransactionBuilder creates new transactions for the bitcoin network.
  # It inherits most of functionality from BTC::TransactionBuilder and adds Chain API
  # to fetch unspent outputs for a set of addresses.
  class TransactionBuilder < BTC::TransactionBuilder

    # Client to use to fetch unspent outputs.
    # Default value is Chain.default_client
    attr_accessor :client

    def unspent_outputs_provider_block
      @unspent_outputs_provider_block ||= proc do |addresses, outputs_amount, outputs_size, fee|
        self.client.get_addresses_unspents(addresses)
      end
    end

    def client
      @client || Chain.default_client
    end

  end # TransactionBuilder
end # Chain