class Instance < ApplicationRecord
  include PgSearch
  has_many :instance_translations
  multisearchable against: %i[name description]
  belongs_to :event
  belongs_to :place
  translates :name, :description
  accepts_nested_attributes_for :translations, reject_if: proc { |x| x['name'].blank? && x['description'].blank? }
  accepts_nested_attributes_for :event
  extend FriendlyId
  friendly_id :name_en, use: %i[slugged finders history]
  mount_uploader :image, ImageUploader
  validates_presence_of :place_id, :start_at
  validates_uniqueness_of :sequence
  belongs_to :proposal
  has_many :instances_users
  has_many :instances_organisers
  has_many :users, through: :instances_users
  has_many :organisers, through: :instances_organisers
  has_many :onetimers, dependent: :destroy
  has_many :pledges
  has_many :rsvps
  has_many :registrations, dependent: :destroy
  has_many :userphotos
  has_many :userthoughts
  has_many :userlinks

  #validate :name_present_in_at_least_one_locale
  scope :temporary, -> { where("id <= 256") }
  scope :between, ->(start_time, end_time) {
    where(["(start_at >= ?  AND  end_at <= ?) OR ( start_at >= ? AND end_at <= ? ) OR (start_at >= ? AND start_at <= ?)  OR (start_at < ? AND end_at > ? )",
           start_time, end_time, start_time, end_time, start_time, end_time, start_time, end_time])
  }
  scope :published, -> { where(published: true) }
  scope :not_cancelled, -> { where('cancelled is not true') }
  scope :meetings, -> { where(is_meeting: true) }
  scope :future, -> { where(["published is true and cancelled is not true and end_at >=  ?", Time.now.utc.strftime('%Y/%m/%d %H:%M')]) }
  scope :past, -> { where(["end_at <  ?", Time.now.utc.strftime('%Y/%m/%d %H:%M')]) }
  scope :current, -> { where(["start_at <=  ? and end_at >= ?", Time.current.utc.strftime('%Y/%m/%d %H:%M'), Time.current.utc.strftime('%Y/%m/%d %H:%M')]) }
  scope :not_open_day, -> { where("event_id != 1") }

  attr_accessor :send_to_pledgers

  def as_json(_options = {})
    {
      id: id,
      title: name,
      description: description || "",
      start: start_at.strftime('%Y-%m-%d %H:%M:00'),
      end: if end_at.nil? || survey_locked == true
             start_at.strftime('%Y-%m-%d %H:%M:00')
           else
             (end_at.strftime('%H:%M') == '23:59' ? '??' : end_at.strftime('%Y-%m-%d %H:%M:00'))
           end,
      allDay: false,
      recurring: false,
      temps: cost_bb,
      cancelled: cancelled,
      url: Rails.application.routes.url_helpers.event_instance_path(event.slug, slug)
    }
  end

  def children
    []
  end

  def self.next_meeting
    current.meetings.or(future.meetings).first
  end

  def feed_date
    updated_at
  end

  def in_future?
    start_at >= Time.current
  end

  def responsible_people
    [event.primary_sponsor, event.secondary_sponsor, organisers].flatten.compact.uniq
  end

  def session_number
    if new_record?
      event.instances.order(:start_at).size + 1
    else
      event.instances.order(:start_at).find_index(self) + 1
    end
  end

  def show_on_website?
    if event.collapse_in_website == true
      (event.instances.published.current.or(event.instances.published.future).sort_by(&:start_at).first == self)
    else
      true
    end
  end

  def cost_in_temps
    if custom_bb_fee.blank?
      if new_record? || spent_biathlon == false
        rate = Rate.get_current.experiment_cost

        start = rate

        for f in 1..(session_number - 1) do
          inrate = rate
          f.times do
            inrate *= 0.9
          end
          start = if inrate < 20
            20
          else
            inrate.round
          end
        end
        start
      elsif spent_biathlon == true && pledges.empty?
        rate =  Rate.order(:created_at).where(["created_at <= ?", created_at]).last.experiment_cost
        start = rate

        for f in 1..(session_number - 1) do
          inrate = rate
          f.times do
            inrate *= 0.9
          end
          start = if inrate < 20
            20
          else
            inrate.round
          end
        end
        start
      else
        pledges.sum(&:pledge)
      end
    else
      custom_bb_fee.to_i
    end
  end

  def viewpoints
    [userphotos, userlinks, userthoughts].flatten.compact
  end

  def is_full?
    if request_registration
      if in_future?
        if max_attendees.present?
          max_attendees - registrations.to_a.delete_if { |x| x.waiting_list == true }.size.to_i <= 0
        else
          false
        end
      else
        false
      end
    else
      false
    end
  end

  private

  def should_generate_new_friendly_id?
    changed?
  end

  def name_en
    name(:en).presence || event.name(:en)
  end

  def name_present_in_at_least_one_locale
    errors.add(:base, "You must specify an event name in at least one available language.") if I18n.available_locales.map { |locale| translation_for(locale).name }.compact.empty?
  end

  def update_image_attributes
    return unless image.present? && image_changed?
    return unless image.file.exists?
    self.image_content_type = image.file.content_type
    self.image_size = image.file.size
    self.image_width, self.image_height = %x(identify -format "%wx%h" #{image.file.path}).split(/x/)
  end
end
