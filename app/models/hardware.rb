class Hardware < ApplicationRecord
  belongs_to :hardwaretype
  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders ]
  validates_presence_of :name
  validates_uniqueness_of :name
  
  scope :monitored, -> () {where(checkable: true)}
  
  def checkable?
    checkable
  end
  
end
