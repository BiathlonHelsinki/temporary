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
  #validate :name_present_in_at_least_one_locale
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
