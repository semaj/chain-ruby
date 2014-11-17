require 'bitcoin'

module Chain
  class Signer
    
    def initialize(block_chain)
      @block_chain = block_chain
    end

    def sign(template, keys)
      template['inputs'].each do |input|
        input['signatures'].each do |sig|
          key = keys[sig['address']]
          next if key.nil? #We only sign what we can for multi-sig
          binary = [sig['hash_to_sign']].pack("H*")
          with_block_chain do 
            signature = key.sign(binary).unpack("H*").first
            sig['public_key'] = key.pub
            sig['signature'] = signature
          end
        end
      end
      template
    end

    def parse_inputs(inputs)
      base58s = inputs.map {|i| i[:private_key]}
      with_block_chain do 
        keys = base58s.map{|b| Bitcoin::Key.from_base58(b)} 
        Hash[keys.map{|key| [key.addr, key] }]
       end
    end
    
    def with_block_chain(&block)
      prev_bc = Bitcoin::NETWORKS.key(Bitcoin.network)
      Bitcoin.network = @block_chain
      result = yield
      Bitcoin.network = prev_bc
      result
    end

  end
end