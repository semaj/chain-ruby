module Chain
  # Base Notification object.
  # See also subclasses AddressNotification,
  # TransactionNotification, NewTransactionNotification, NewBlockNotification
  class Notification

  end

  class AddressNotification < Notification
    def self.type
      "address"
    end
  end

  class TransactionNotification < Notification
    def self.type
      "transaction"
    end
  end

  class NewTransactionNotification < Notification
    def self.type
      "new-transaction"
    end
  end

  class NewBlockNotification < Notification
    def self.type
      "new-block"
    end
  end

end
