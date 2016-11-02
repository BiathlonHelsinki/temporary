class Email < ApplicationRecord
  extend FriendlyId
  friendly_id :subject , :use => [ :slugged, :finders, :history]
  
  validates_presence_of :subject, :body
  
  scope :published, -> () { where('sent_at is not null') }
  
  def feed_date
    sent_at
  end
  
end
