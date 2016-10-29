class Proposal < ApplicationRecord
  belongs_to :user
  has_many :images, as: :item, :dependent => :destroy
  has_many :pledges, as: :item, :dependent => :destroy
  accepts_nested_attributes_for :images, :reject_if => proc {|attributes| attributes['image'].blank? && attributes['image_cache'].blank?}, :allow_destroy => true
  accepts_nested_attributes_for :pledges
  validates_presence_of :user_id, :name, :short_description, :timeframe, :goals, :intended_participants
  has_many :comments, as: :item, :dependent => :destroy
  has_many :instances
  has_many :activities, dependent: :destroy, as: :item
  after_create :add_to_activity_feed
  after_update :add_to_activity_feed_edited
 
  scope :archived, -> () { where(stopped: true) }
  scope :active, -> () { where(stopped: false) }

  def comments_and_pledges
    [comments, pledges].flatten.sort_by(&:updated_at)
  end
  
  def add_to_activity_feed
    Activity.create(user: user, item: self, description: 'proposed')
  end
  
  def add_to_activity_feed_edited
    Activity.create(user: user, item: self, description: 'edited') if self.short_description_changed? || self.goals_changed? || self.name_changed? || self.intended_participants_changed?
  end
  
  def self.schedulable
    all.to_a.delete_if { |x| x.pledged - x.instances.published.sum(&:cost_in_temps) <  x.needed_for_next }
  end
  
  def feed_date
    comments_and_pledges.empty? ? updated_at : comments_and_pledges.last.updated_at
  end
  
  def recurs?
    recurrence == 2 || recurrence == 3
  end
  
  def needed_array
    rate = Rate.get_current.experiment_cost
    array = [rate]
    if recurs?
      for f in 1..20  do 
        inrate = rate
        f.times do
          inrate *= 0.9;
        end
        if inrate < 20
          start = 20
        else
          start = inrate.round
        end
        array.push(start)
      end
    end
    return array
  end
  
  def cumulative_needed_for(val)
    rate = Rate.get_current.experiment_cost
    array = [rate]
    cum = rate
    if recurs?
      for f in 1..val  do 
        inrate = rate
        f.times do
          inrate *= 0.9;
        end
        if inrate < 20
          start = 20
        else
          start = inrate.round
        end
        array.push(start)
        cum += start
      end
      return cum
    else
      return rate
    end
  end
  
  def needed_for(val)
    rate = Rate.get_current.experiment_cost
    array = [rate]
    if recurs?
      for f in 1..val  do 
        inrate = rate
        f.times do
          inrate *= 0.9;
        end
        if inrate < 20
          start = 20
        else
          start = inrate.round
        end
        array.push(start)
      end
      return array[val]
    else
      return rate
    end
  end
  
  def has_for(val)
    max = cumulative_needed_for(val)
    if pledged >= max
      needed_for(val)
    else
      if  needed_for(val) - (max - pledged) <= 0
        0
      else
         needed_for(val) - (max - pledged)
      end
    end
  end
    
  
  def needed_for_next
    rate = Rate.get_current.experiment_cost
    if recurs?
      if instances.published.empty?
        Rate.get_current.experiment_cost
      else
        r = instances.published.order(:start_at).last.cost_in_temps * 0.9
        if r.round < 20
          20
        else
          r.round
        end
      end
    else
      if instances.published.empty?
        Rate.get_current.experiment_cost
      else
        0
      end
    end
  end
  
  def has_enough?
    remaining_pledges >= needed_for_next
  end
  
  def number_that_can_be_scheduled
    rate = Rate.get_current.experiment_cost
    tally = 0
    if recurs?
      needed_array.each_with_index do |val, index|
        tally += val
        
        if remaining_pledges >= tally
          next
        else
          return index 
        end
      end
    else
      return (remaining_pledges >= rate) ? 1 : 0
    end
  end
  

  def total_needed_with_recurrence
    rate = Rate.get_current.experiment_cost
    if recurs?
      start = rate
      if intended_sessions == 0
        cumulative_needed_for(instances.published.size)
      else
        for f in 1..(intended_sessions-1)  do 
          inrate = rate
          f.times do
            inrate *= 0.9;
          end
          if inrate < 20
            start += 20
          else
            start += inrate.round
          end
        end
        return start
      end
    else
      return rate
    end
  end
  
  def pledgeable?
    if recurs?
      if intended_sessions == 0
        true
      else
        total_needed_with_recurrence - spent - remaining_pledges > 0
      end
    else
      total_needed_with_recurrence - spent - remaining_pledges > 0
    end
  end
  
  def maximum_pledgeable(user)
    if pledges.map(&:user).include?(user)  # user has already pledged
      if has_enough?
        if recurs?
          if intended_sessions == 0
            user.available_balance + pledges.where(user: user).pledge
          else
            (user.available_balance + pledges.where(user: user).pledge) > cumulative_needed_for(intended_sessions) ? cumulative_needed_for(intended_sessions) : (user.available_balance + pledges.where(user: user).pledge) 
          end
        else
          pledges.where(user: user).pledge
        end
      
      elsif pledges.map(&:user).size == 1
        Rate.get_current.experiment_cost - 1
      else
        cumulative_needed_for(intended_sessions) 
      end
    else    # user has not yet pledged
      if has_enough?
        if recurs?
          if intended_sessions == 0
            user.available_balance
          else
             (user.available_balance  > cumulative_needed_for(intended_sessions)) ? cumulative_needed_for(intended_sessions) : user.available_balance
           end
        else
          0
        end

      elsif pledges.to_a.delete_if(&:new_record?).empty?
        if instances.published.empty?
          needed_for_next - 1
        else
          needed_for_next
        end
      else
        needed_for_next
      end
    end
  end
  
  def pledged
    pledges.sum(&:pledge)
  end
  
  def remaining_pledges
    pledged - spent
    #instances.published.sum(&:cost_in_temps)
  end
  
  def discussion
    [pledges, comments].flatten.compact
  end
  
  def scheduled?
    !instances.published.empty?
  end
  
  def spent
    # activities.where(addition: -1).map(&:ethtransaction).sum(&:value) rescue 0
    pledges.converted.sum(&:pledge)
  end
  
  def next_instance
    if scheduled?
      if instances.first.experiment.instances.current.or(instances.first.experiment.instances.future).order(:start_at).empty?
        nil
      else
       instances.first.experiment.instances.current.or(instances.first.experiment.instances.future).order(:start_at).first
        
      end
    else
      nil
    end
  end
end
