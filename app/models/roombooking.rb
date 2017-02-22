class Roombooking < ApplicationRecord
  belongs_to :user
  belongs_to :ethtransaction
  belongs_to :rate
  has_many :activities, as: :item, dependent: :destroy
    
  validates_presence_of :user_id, :rate_id, :ethtransaction_id, :day
  
  scope :between, -> (start_time, end_time) { 
    where( [ "(day >= ?  AND  day <= ?)",  start_time, end_time ])
  }
  

  def as_json(options = {})
    {
      :id => self.id,
      :title => self.user.display_name + "\n" + (self.purpose || '') ,
      :description => self.purpose || "",
      icon_url: self.user.avatar.url(:thumb).gsub(/development/, 'production'),
      :start => day.strftime('%Y-%m-%d 00:00:01'),
      :end =>  day.strftime('%Y-%m-%d 23:59:59'),
      :allDay => true, 
      :recurring => false,
      :temps => self.rate.room_cost,
      :url => Rails.application.routes.url_helpers.user_path(self.user)
    }
    
  end
  
end
