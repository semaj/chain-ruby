module Chain

  # Base class for Chain errors.
  class ChainError < StandardError; end

  # Raised when an unexpected error occurs during parsing
  # or encoding a message.
  class ChainFormatError < ChainError; end

  # Raised when a network connection fails or server is unreachable.
  class ChainNetworkError < ChainError; end

end