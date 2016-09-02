class Proposal < ApplicationRecord
  belongs_to :user
  has_many :images, as: :item, :dependent => :destroy
  has_many :pledges, as: :item, :dependent => :destroy
  accepts_nested_attributes_for :images
  accepts_nested_attributes_for :pledges
  validates_presence_of :user_id, :name, :short_description, :timeframe, :goals, :intended_participants
  has_many :comments, as: :item, :dependent => :destroy
  has_many :instances
  after_create :add_to_activity_feed
  after_update :add_to_activity_feed_edited
 
  
  def add_to_activity_feed
    Activity.create(user: user, item: self, description: 'proposed')
  end
  
  def add_to_activity_feed_edited
    Activity.create(user: user, item: self, description: 'edited')
  end
  
  def self.schedulable
    all.to_a.delete_if{|x| x.pledged < Rate.get_current.experiment_cost }
  end
  
  def has_enough?
    pledged >= Rate.get_current.experiment_cost
  end
  
  def maximum_pledgeable(user)
    if pledges.map(&:user).include?(user)  # user has already pledged
      if has_enough?
        user.available_balance + pledges.where(user: user).pledge
      elsif pledges.map(&:user).size == 1
        Rate.get_current.experiment_cost - 1
      else
        user.available_balance
      end
    else    # user has not yet pledged
      if has_enough?
        user.available_balance   # no limit 
      elsif pledges.to_a.delete_if(&:new_record?).empty?
        Rate.get_current.experiment_cost - 1
      else
        user.available_balance
      end
    end
  end
  
  def pledged
    pledges.sum(&:pledge)
  end
  
  def discussion
    [pledges, comments].flatten.compact
  end
  
  def scheduled?
    !instances.empty?
  end
  
  def next_instance
    if scheduled?
      if instances.future.order(:start_at).empty?
        nil
      else
       instances.future.order(:start_at).first
        
      end
    else
      nil
    end
  end
end
