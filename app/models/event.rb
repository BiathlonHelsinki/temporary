class Event < ApplicationRecord
  # stub to catch events which should be called experiments but in polymorphic...
  extend FriendlyId
  friendly_id :name_en , :use => [ :slugged, :finders ] # :history]
  belongs_to :place
  belongs_to :primary_sponsor, class_name: 'User'
  belongs_to :secondary_sponsor, class_name: 'User'
  translates :name, :description, :fallbacks_for_empty_translations => true
  has_many :pledges
end