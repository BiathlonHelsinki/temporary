class Instance < ApplicationRecord
  belongs_to :experiment, foreign_key: 'event_id'
  belongs_to :place
  translates :name, :description, :fallbacks_for_empty_translations => true
  accepts_nested_attributes_for :translations, :reject_if => proc {|x| x['name'].blank? && x['description'].blank? }
  extend FriendlyId
  friendly_id :name_en , :use => [ :slugged, :finders ] # :history]
  mount_uploader :image, ImageUploader
  validates_presence_of :place_id, :start_at
  validates_uniqueness_of :sequence
  belongs_to :proposal
  has_many :instances_users
  has_many :users, through: :instances_users
  has_many :onetimers, dependent: :destroy
  #validate :name_present_in_at_least_one_locale
  scope :between, -> (start_time, end_time) { 
    where( [ "(start_at >= ?  AND  end_at <= ?) OR ( start_at >= ? AND end_at <= ? ) OR (start_at >= ? AND start_at <= ?)  OR (start_at < ? AND end_at > ? )",
    start_time, end_time, start_time, end_time, start_time, end_time, start_time, end_time])
  }
  scope :published, -> () { where(published: true) }
  scope :meetings, -> () {where(is_meeting: true)}
  scope :future, -> () {where(["start_at >=  ?", Time.now.strftime('%Y/%m/%d %H:%M')]) }
  
  def as_json(options = {})
    {
      :id => self.id,
      :title => self.name,
      :description => self.description || "",
      :start => start_at.strftime('%Y-%m-%d %H:%M:00'),
      :end => end_at.nil? ? start_at.strftime('%Y-%m-%d %H:%M:00') : end_at.strftime('%Y-%m-%d %H:%M:00'),
      :allDay => false, 
      :recurring => false,
      :url => Rails.application.routes.url_helpers.instance_path(slug),
      #:color => "red"
    }

  end
  
  def children
    []
  end
  
  def self.next_meeting
    self.future.meetings.first
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
