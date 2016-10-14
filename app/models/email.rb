class Email < ApplicationRecord
  extend FriendlyId
  friendly_id :subject , :use => [ :slugged, :finders, :history]
  
  validates_presence_of :subject, :body
end
