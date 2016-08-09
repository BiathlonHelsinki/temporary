class Proposal < ApplicationRecord
  belongs_to :user
  has_many :images, as: :item
end
