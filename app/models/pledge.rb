class Pledge < ApplicationRecord
  belongs_to :item, polymorphic: true, touch: true
  has_many :activities, as: :item
  belongs_to :user
  after_save :update_activity_feed
  before_destroy :withdraw_activity
  validate :check_balance
  after_save :notify_if_enough
  validates_numericality_of :pledge, greater_than_or_equal_to: 0
  acts_as_paranoid
  validate :one_per_user
  
  def check_balance
    user.update_balance_from_blockchain
    if pledge < 1 || pledge > user.latest_balance
      errors.add(:pledge, 'You cannot pledge this amount.')
    end
  end
  
  def one_per_user
    unless item.pledges.where(user: user).to_a.delete_if{|x| x == self}.empty?
      errors.add(:user, 'You have already pledged to this. Please edit your pledge.')
    end
  end
  
  def content
    comment
  end
  def name
    item.name
  end
  
  def notify_if_enough
    
    if (item.pledged + pledge ) >= Rate.get_current.experiment_cost
      if item.notified != true
        
        begin
          ProposalMailer.proposal_for_review(self.item).deliver 
          item.notified = true
          item.save
        rescue

          item.notified = false
          item.save
        end
      end
    end
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
      Activity.create(user: user, item: self, description: "pledged to", extra_info: pledge, addition: 0)
    else
      Activity.create(user: user, item: self, description: "edited their pledge to", extra_info: pledge, addition: 0)
    end
  end
  
  def withdraw_activity
    item.comments << Comment.create(user: user, content: "Pledge of #{pledge.to_s}#{ENV['currency_symbol']} withdrawn.", addition: 0, systemflag: true)
    Activity.create(user: user, item: item, description: "withdrew a pledge", extra_info: "#{pledge.to_s}", addition: 0)
  end
  
end
