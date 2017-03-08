class Instance < ApplicationRecord
  belongs_to :experiment, foreign_key: 'event_id'
  belongs_to :place
  translates :name, :description, :fallbacks_for_empty_translations => true
  accepts_nested_attributes_for :translations, :reject_if => proc {|x| x['name'].blank? && x['description'].blank? }
  extend FriendlyId
  friendly_id :name_en , :use => [ :slugged, :finders, :history]
  mount_uploader :image, ImageUploader
  validates_presence_of :place_id, :start_at
  validates_uniqueness_of :sequence
  belongs_to :proposal
  has_many :instances_users
  has_many :users, through: :instances_users
  has_many :onetimers, dependent: :destroy
  has_many :pledges
  has_many :rsvps
  has_many :registrations, dependent: :destroy
  
  #validate :name_present_in_at_least_one_locale
  scope :between, -> (start_time, end_time) { 
    where( [ "(start_at >= ?  AND  end_at <= ?) OR ( start_at >= ? AND end_at <= ? ) OR (start_at >= ? AND start_at <= ?)  OR (start_at < ? AND end_at > ? )",
    start_time, end_time, start_time, end_time, start_time, end_time, start_time, end_time])
  }
  scope :published, -> () { where(published: true) }
  scope :meetings, -> () {where(is_meeting: true)}
  scope :future, -> () {where(["end_at >=  ?", Time.now.utc.strftime('%Y/%m/%d %H:%M')]) }
  scope :past, -> () {where(["end_at <  ?", Time.now.utc.strftime('%Y/%m/%d %H:%M')]) }
  scope :current, -> () { where(["start_at <=  ? and end_at >= ?", Time.current.utc.strftime('%Y/%m/%d %H:%M'), Time.current.utc.strftime('%Y/%m/%d %H:%M') ]) }
  scope :not_open_day,  -> ()  { where("event_id != 1")}

  attr_accessor :send_to_pledgers
  
  def as_json(options = {})
    {
      :id => self.id,
      :title => self.name,
      :description => self.description || "",
      :start => start_at.strftime('%Y-%m-%d %H:%M:00'),
      :end => end_at.nil? ? start_at.strftime('%Y-%m-%d %H:%M:00') : (end_at.strftime('%H:%M') == '23:59' ? '??' : end_at.strftime('%Y-%m-%d %H:%M:00')),
      :allDay => false, 
      :recurring => false,
      :temps => self.cost_bb,
      :url => Rails.application.routes.url_helpers.experiment_instance_path(experiment.slug, slug)
    }
    
  end
  
  def children
    []
  end
  
  def self.next_meeting
    self.current.meetings.or(self.future.meetings).first
  end
  
  def feed_date
    updated_at
  end
  
  def in_future?
    start_at >= Time.current
  end
  
  def session_number
    if new_record?
      experiment.instances.order(:start_at).size + 1
    else 
      experiment.instances.order(:start_at).find_index(self) + 1
    end
  end
  
  def show_on_website?
    experiment.collapse_in_website == true ? 
      (experiment.instances.published.current.or(experiment.instances.published.future).sort_by(&:start_at).first == self ? true : false) 
      : true
  end
  
  def cost_in_temps
    if custom_bb_fee.blank?
      rate = Rate.get_current.experiment_cost
      # if proposal.recurrence == 2 || proposal.recurrence == 3
        start = rate
    
        for f in 1..(session_number-1)  do 
          inrate = rate
          f.times do
            inrate *= 0.9;
          end
          if inrate < 20
            start = 20
          else
            start = inrate.round
          end
        end
        return start
      else
        return custom_bb_fee.to_i
      end

    # else
    #   return rate
    # end
  end
  
  def is_full?
    if request_registration
      if in_future?
        if !max_attendees.blank?
          if max_attendees - self.registrations.to_a.delete_if{|x| x.waiting_list == true}.size.to_i <= 0
            return true
          else
            return false
          end
        else 
          return false
        end
      else 
        return false
      end
    else
      return false
    end
  end 
  
  private
  
  
  def should_generate_new_friendly_id?
    changed?
  end
  
  def name_en
    self.name(:en).blank? ? experiment.name(:en) : self.name(:en)
  end
  
  def name_present_in_at_least_one_locale
    if I18n.available_locales.map { |locale| translation_for(locale).name }.compact.empty?
      errors.add(:base, "You must specify an event name in at least one available language.")
    end
  end
  
  def update_image_attributes
    if image.present? && image_changed?
      if image.file.exists?
        self.image_content_type = image.file.content_type
        self.image_size = image.file.size
        self.image_width, self.image_height = `identify -format "%wx%h" #{image.file.path}`.split(/x/)
      end
    end
  end
  
end
