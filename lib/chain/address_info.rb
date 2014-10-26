module Chain
  # Various information about a given address.
  # Use Client#get_address and Client#get_addresses to access this data.
  class AddressInfo

    # A BTC::Address object described by the properties that follow.
    attr_reader :address

    # The confirmed balance of the address in satoshis (1 satoshi = 0.00000001 BTC).
    attr_reader :balance

    # The total confirmed amount in satoshis that the address has ever received.
    attr_reader :received

    # The total confirmed amount in satoshis that the address has ever sent.
    attr_reader :sent

    # The total unconfirmed amount in satoshis that has been sent to the address.
    # This value is not included in "received".
    attr_reader :unconfirmed_received

    # The total unconfirmed amount in satoshis that has been sent from the address.
    # This value is not included in "sent".
    attr_reader :unconfirmed_sent

    # The total unconfirmed balance of the address.
    # This is calculated as (unconfirmed_received - unconfirmed_sent).
    # This value is not included in "balance".
    attr_reader :unconfirmed_balance

    def initialize(dictionary: {})
      @address = BTC::Address.with_string(ensure_type(dictionary["hash"], String))
      @balance              = dictionary["balance"].to_i
      @received             = dictionary["received"].to_i
      @sent                 = dictionary["sent"].to_i
      @unconfirmed_received = dictionary["unconfirmed_received"].to_i
      @unconfirmed_sent     = dictionary["unconfirmed_sent"].to_i
      @unconfirmed_balance  = dictionary["unconfirmed_balance"].to_i
    end

    private

    def ensure_type(value, type)
      if value.is_a?(type)
        value
      else
        raise ChainFormatError, "Expected value of type #{type}, got #{value.class} (#{value.inspect})"
      end
    end

  end
end
