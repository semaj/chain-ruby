module Chain
  # Raised when an unexpected error occurs in either
  # the HTTP request or the parsing of the response body.
  class ChainError < Exception
    def self.exception(msg)
      super.tap {|e| e.set_backtrace msg.backtrace if msg.kind_of?(Exception) }
    end
  end
end
