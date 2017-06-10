class BlockchainTransaction < ApplicationRecord
  belongs_to :transaction_type
  belongs_to :account
  belongs_to :ethtransaction
  belongs_to :activity
end
