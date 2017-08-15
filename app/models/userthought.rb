class Userthought < ApplicationRecord
  belongs_to :instance
  belongs_to :user
  
  after_create :update_activity_feed
  before_destroy :withdraw_activity

  scope :by_user, ->(user_id) { where(user_id: user_id) }
 
  
  def update_activity_feed
    if created_at == updated_at
      # assume it's new
      Activity.create(user_id: user_id, item: self.instance, description: "shared_some_words_about", extra: self, addition: 0)
    end

  end
  
  def withdraw_activity
    Activity.create(user: user, item: self.instance, description: "removed_some_words_about", addition: 0)
  end
  
  
end
  
