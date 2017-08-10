class Userphotoslot < ApplicationRecord
  belongs_to :user
  belongs_to :userphoto
  belongs_to :ethtransaction
  belongs_to :activity
  
  scope :empty, ->() { where(userphoto: nil) }
  scope :unpaid, ->() { where(ethtransaction: nil) }
end
