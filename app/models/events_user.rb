class EventsUser < ActiveRecord::Base
  belongs_to :experiment
  belongs_to :user
  

end