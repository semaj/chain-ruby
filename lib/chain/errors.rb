module Chain

  # Base class for Chain errors.
  class ChainError < StandardError; end

  # Raised when an unexpected error occurs during parsing
  # or encoding a message.
  class ChainFormatError < ChainError; end

  # Raised when a network connection fails or server is unreachable.
  class ChainNetworkError < ChainError
    attr_accessor :http_code
    attr_accessor :chain_code
    def initialize(message = nil, http_code = nil, chain_code = nil)
      super(message)
      @http_code = http_code
      @chain_code = chain_code
    end
  end

  # Raised when transaction cannot be broadcasted because it is invalid or non-canonical.
  class ChainBroadcastError < ChainError; end
end