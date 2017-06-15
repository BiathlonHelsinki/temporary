class BlockchainTransaction < ApplicationRecord
  belongs_to :transaction_type
  belongs_to :account
  belongs_to :ethtransaction
  has_one :activity
end
