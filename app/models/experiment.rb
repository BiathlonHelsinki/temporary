class Experiment < ApplicationRecord
  self.table_name = "events"
  belongs_to :place
  belongs_to :primary_sponsor, class_name: 'User'
  belongs_to :secondary_sponsor, class_name: 'User'
  translates :name, :description, :fallbacks_for_empty_translations => true
  accepts_nested_attributes_for :translations, :reject_if => proc {|x| x['name'].blank? && x['description'].blank? }
  belongs_to :place  
  has_many :activities, as: :item,  dependent: :destroy, source_type: 'Event'
  resourcify

  extend FriendlyId
  friendly_id :name_en , :use => [ :slugged, :finders ] # :history]
  mount_uploader :image, ImageUploader
  validates_presence_of :place_id, :start_at, :primary_sponsor_id, :sequence
  validate :name_present_in_at_least_one_locale
  before_save :update_image_attributes

  

  
  acts_as_nested_set
  has_many :instances, foreign_key: 'event_id', dependent: :destroy
  has_many :pledges, as: :item,  dependent: :destroy, source_type: 'Event'
  before_validation :make_first_instance
  validate :at_least_one_instance
  validates_uniqueness_of :sequence
  
  scope :published, -> () { where(published: true) }
  scope :has_events_on, -> (*args) { where(['published is true and (date(start_at) = ? OR (end_at is not null AND (date(start_at) <= ? AND date(end_at) >= ?)))', args.first, args.first, args.first] )}
  scope :between, -> (start_time, end_time) { 
    where( [ "(start_at >= ?  AND  end_at <= ?) OR ( start_at >= ? AND end_at <= ? ) OR (start_at >= ? AND start_at <= ?)  OR (start_at < ? AND end_at > ? )",
    start_time, end_time, start_time, end_time, start_time, end_time, start_time, end_time])
  }
  
  def end_date
    self.end_at.nil? ? (instances.sort_by(&:start_at).last.end_at.nil? ? start_at : instances.sort_by(&:start_at).last.end_at) : self.end_at
  end
  
  def future?
    self.start_at >= Date.parse(Time.now.strftime('%Y/%m/%d'))
  end
  
  def self.collection_to_json(collection = roots)
    collection.inject([]) do |arr, model|
      if model.children.empty?
        if model.class == Instance
          arr << { name:  model.sequence + " : " + model.name }
        else
          if model.instances.size == 1
            arr << { name:  model.sequence + " : " + model.name }
          else
            arr << { name:   model.sequence + " : " + model.name, children: collection_to_json(model.instances) }
          end
        end
      else
        
        arr << { name: model.sequence + " : " + model.name, children: collection_to_json(model.instances) +
           collection_to_json(model.children) }
      end
    end
  end
  
  def make_first_instance

    if instances.empty?
      
      instances << Instance.new(cost_bb: cost_bb, sequence: sequence, cost_euros: cost_euros, start_at: start_at, end_at: end_at,
                                   place_id: place_id, published: false, translations_attributes: [{locale: 'en', name: name(:en), description: description(:en)}])

    end                          
  end
  
  def name_en
    self.name(:en)
  end
  
  def name_present_in_at_least_one_locale
    if I18n.available_locales.map { |locale| translation_for(locale).name }.compact.empty?
      errors.add(:base, "You must specify an event name in at least one available language.")
    end
  end
  
  def at_least_one_instance
    if instances.empty?
      errors.add(:base, "At least one instance of this experiment must exist.")
    end
  end
  
  def place_name
    place.blank? ? nil : place.name
  end
  
  def title
    name    
  end
  
  private
  
  def should_generate_new_friendly_id?
    changed?
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