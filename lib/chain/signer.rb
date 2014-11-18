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

    def parse_inputs(pks)
      with_block_chain do
        keys = pks.map do |pk|
          if pk =~ /\A\h{64}\z/
            [Bitcoin::Key.new(pk), Bitcoin::Key.new(pk, nil, compressed: false)]
          else
            Bitcoin::Key.from_base58(pk)
          end
        end.flatten
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
