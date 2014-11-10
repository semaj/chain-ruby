require 'btcruby'

# Chain-specific extensions to BTC::Block
module BTC
  BTC::Block # make sure class is loaded with its proper superclass.
  class Block
    attr_accessor :chain_client
    attr_accessor :transaction_ids
    def self.with_chain_dictionary(dict, chain_client: nil)
      # {
      #   "hash": "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f",
      #   "previous_block_hash": null,
      #   "height": 0,
      #   "confirmations": 329417,
      #   "version": 1,
      #   "merkle_root": "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
      #   "time": "2009-01-03T18:15:05.000Z",
      #   "nonce": 2083236893,
      #   "difficulty": 1.0,
      #   "bits": "1d00ffff",
      #   "transaction_hashes": [
      #     "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b"
      #   ],
      #   "chain_note": "The transaction contained in this block is the coinbase transaction from the genesis block. Its funds are not technically spendable and therefore, the transaction does not technically exist."
      # }
      
      block_id = dict["hash"]
      block = BTC::Block.new(
        version:           dict["version"],
        previous_block_id: dict["previous_block_hash"],
        merkle_root:       BTC.hash_from_id(dict["merkle_root"]),
        timestamp:         Time.parse(dict["time"]).to_i,
        nonce:             dict["nonce"],
        bits:              dict["bits"].to_s.to_i(16), # "bits": "1d00ffff",
      )
      # Make sure we restore the block correctly.
      if block.block_id != block_id
        raise Chain::ChainFormatError, "Block has invalid hash (should be #{block_id})!"
      end
      block.height          = dict["height"]
      block.confirmations   = dict["confirmations"]
      block.transaction_ids = dict["transaction_hashes"]
      block.chain_client    = chain_client
      return block
    end
    
    def transactions
      if (!@transactions || @transactions.size == 0) && @transaction_ids
        client = @chain_client || Chain.default_client
        @transactions = @transaction_ids.map do |txid|
          tx = client.get_transaction(txid)
          if tx.transaction_id != txid
            raise Chain::ChainFormatError, "Invalid tx: #{tx.inspect} (id: #{txid})"
          end
          tx
        end
      end
      return @transactions
    end
  end # BTC::Block
end
