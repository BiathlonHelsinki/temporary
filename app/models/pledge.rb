class Pledge < ApplicationRecord
  belongs_to :item, polymorphic: true
  has_many :activities, as: :item,  dependent: :destroy
  belongs_to :user
  after_save :update_activity_feed
  before_destroy :withdraw_activity
  validate :check_balance
  
  def check_balance
    user.update_balance_from_blockchain
    if pledge < 1 || pledge > user.latest_balance
      errors.add(:pledge, 'You cannot pledge this amount.')
    end
  end
  
  def content
    comment
  end
  
  def image?
    false
  end
  
  def attachment?
    false
  end
  
  def update_activity_feed
    if created_at == updated_at
      # assume it's new
      Activity.create(user: user, item: item, description: "pledged #{pledge.to_s}#{ENV['currency_symbol']} to ")
    else
      Activity.create(user: user, item: item, description: "edited their pledge of #{pledge.to_s}#{ENV['currency_symbol']} to ")
    end
  end
  
  def withdraw_activity
    item.comments << Comment.create(user: user, content: "Pledge of #{pledge.to_s}#{ENV['currency_symbol']} withdrawn.", systemflag: true)
    Activity.create(user: user, item: item, description: "withdrew a pledge of #{pledge.to_s}#{ENV['currency_symbol']} from ")
  end
  
end
