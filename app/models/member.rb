class Member < ApplicationRecord
  belongs_to :source, polymorphic: true
  belongs_to :user
  validates_uniqueness_of :user_id, message: 'is already part of this group.',  scope: [:source_type, :source_id]
  has_many :activities, as: :item

  def username
    user.nil? ? nil : user.username
  end
end
