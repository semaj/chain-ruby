require 'bitcoin'

module Chain
  module Signer

    def self.sign(template, keys)
      template['inputs'].each do |input|
        input['signatures'].each do |sig|
          key = keys[sig['address']]
          next if key.nil? #We only sign what we can for multi-sig
          binary = [sig['hash_to_sign']].pack("H*")
          signature = key.sign(binary).unpack("H*").first

          sig['public_key'] = key.pub
          sig['signature'] = signature
        end
      end
      template
    end

    def self.parse_inputs(inputs)
      base58s = inputs.map {|i| i[:private_key]}
      keys = base58s.map{|b| Bitcoin::Key.from_base58(b)}
      Hash[keys.map{|key| [key.addr, key] }]
    end

  end
end
