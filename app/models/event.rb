class Event < ApplicationRecord
  self.table_name = "events"
  include PgSearch
  belongs_to :primary_sponsor, class_name: 'User'
  belongs_to :secondary_sponsor, class_name: 'User'
  translates :name, :description
  accepts_nested_attributes_for :translations, reject_if: proc { |x| x['name'].blank? && x['description'].blank? }
  belongs_to :place
  has_many :notifications, as: :item
  has_many :activities, -> { where(item_type: "Event") }, as: :item, dependent: :destroy
  has_many :pledges, -> { where(item_type: "Event") }, as: :item, dependent: :destroy
  resourcify
  belongs_to :proposal

  extend FriendlyId
  friendly_id :name_en, use: %i[slugged finders] # :history]
  mount_uploader :image, ImageUploader
  process_in_background :image
  validates_presence_of :place_id, :start_at, :primary_sponsor_id, :sequence, :proposal_id
  validate :name_present_in_at_least_one_locale
  before_save :update_image_attributes
  has_many :comments, as: :item, dependent: :destroy

  acts_as_nested_set
  has_many :instances, dependent: :destroy

  before_validation :make_first_instance
  validate :at_least_one_instance
  validates_uniqueness_of :sequence

  scope :published, -> { where(published: true) }
  scope :has_events_on, ->(*args) { where(['published is true and (date(start_at) = ? OR (end_at is not null AND (date(start_at) <= ? AND date(end_at) >= ?)))', args.first, args.first, args.first]) }
  scope :between, ->(start_time, end_time) {
    where(["(start_at >= ?  AND  end_at <= ?) OR ( start_at >= ? AND end_at <= ? ) OR (start_at >= ? AND start_at <= ?)  OR (start_at < ? AND end_at > ? )",
           start_time, end_time, start_time, end_time, start_time, end_time, start_time, end_time])
  }

  def as_mentionable
    {
      created_at: created_at,
      id: id,
      slug: slug,
      image_url: image.url(:thumb).gsub(/development/, 'production'),
      name: name,
      route: 'experiments',
      updated_at: updated_at
    }
  end

  def discussion
    comments
  end

  def end_date
    if end_at.nil?
      instances.sort_by(&:start_at).last.end_at.nil? ? start_at : instances.sort_by(&:start_at).last.end_at
    else
      end_at
    end
  end

  def future?
    start_at >= Date.parse(Time.now.strftime('%Y/%m/%d'))
  end

  def self.collection_to_json(collection = roots)
    collection.inject([]) do |arr, model|
      arr << if model.children.empty?
        if model.class == Instance
          { name: model.sequence + " : " + model.name }
        elsif model.instances.size == 1
          { name: model.sequence + " : " + model.name }
        else
          { name: model.sequence + " : " + model.name, children: collection_to_json(model.instances) }
        end
      else

        { name: model.sequence + " : " + model.name, children: collection_to_json(model.instances) +
                                                               collection_to_json(model.children) }
      end
    end
  end

  def make_first_instance
    return unless instances.empty?

    instances << Instance.new(cost_bb: cost_bb, sequence: sequence, cost_euros: cost_euros, start_at: start_at, end_at: end_at,
                              place_id: place_id, published: false, translations_attributes: [{ locale: 'en', name: name(:en), description: description(:en) }])
  end

  def name_en
    name(:en)
  end

  def name_present_in_at_least_one_locale
    return unless I18n.available_locales.map { |locale| translation_for(locale).name }.compact.empty?
    errors.add(:base, "You must specify an event name in at least one available language.")
  end

  def is_valid?
    true
  end

  def has_enough?
    pledges.unconverted.sum(&:pledge) >= needed_for_next
  end

  def pledged
    pledges.sum { |x| x.pledge.to_i }
  end

  def remaining_pledges
    pledges.unconverted.sum(&:pledge)
  end

  delegate :recurs?, to: :proposal

  def published_instances
    instances.published.size
  end

  def maximum_pledgeable(user)
    if pledges.map(&:user).include?(user) # user has already pledged
      if has_enough?
        if recurs?
          if intended_sessions == 0
            user.available_balance + (pledges.unconverted.find_by(user:).nil? ? 0 : pledges.unconverted.find_by(user:).pledge)
          elsif (user.available_balance + (pledges.unconverted.find_by(user:).nil? ? 0 : pledges.unconverted.find_by(user:).pledge)) > cumulative_needed_for(intended_sessions)
            cumulative_needed_for(intended_sessions)
          else
            (user.available_balance + pledges.unconverted.find_by(user:).pledge)
          end
        else
          pledges.unconverted.find_by(user:).pledge
        end

      elsif pledges.map(&:user).size == 1
        Rate.get_current.experiment_cost - 1
      else
        [proposal.cumulative_needed_for(intended_sessions).to_i, user.available_balance].max
      end
    elsif has_enough? # user has not yet pledged
      if recurs?
        if intended_sessions == 0
          user.available_balance
        else
          user.available_balance > cumulative_needed_for(intended_sessions) ? cumulative_needed_for(intended_sessions) : user.available_balance
        end
      else
        0
      end

    elsif pledges.to_a.delete_if(&:new_record?).empty?
      if instances.published.empty?
        total_needed_with_recurrence - 1
      else
        total_needed_with_recurrence
      end
    else
      total_needed_with_recurrence
    end
  end

  delegate :number_that_can_be_scheduled, to: :proposal

  delegate :intended_sessions, to: :proposal

  def self.schedulable
    includes(:pledges).to_a.delete_if { |x| x.remaining_pledges == 0 }.delete_if { |x| x.remaining_pledges == 0 }.sort_by(&:name)
  end

  delegate :total_needed_with_recurrence, to: :proposal

  def dormant?
    return false if created_at >= 3.months.ago

    return unless (pledges.empty? || pledges.last.created_at < 3.months.ago) && (comments.empty? || comments.last.created_at < 3.months.ago) && (instances.published.empty? || instances.published.last.start_at < 3.months.ago)
    true
  end

  def last_activity
    [created_at, (pledges.empty? ? nil : pledges.last.created_at), (comments.empty? ? nil : comments.last.created_at), (instances.published.empty? ? nil : instances.published.order(:start_at).last.start_at)].compact.max
  end

  def needed_for_next
    if proposal.is_month_long == true
      20 * Time.days_in_month(instances.published.order(:start_at).last.end_at.month + 1, instances.published.order(:start_at).last.end_at.month == 12 ? instances.published.order(:start_at).last.end_at.year + 1 : instances.published.order(:start_at).last.end_at.year)
    else

      rate = Rate.get_current.experiment_cost
      # if proposal.recurs?
      if instances.published.size == 0
        if proposal.recurrence == 2 && proposal.require_all == true
          proposal.total_needed_with_recurrence
        else
          Rate.get_current.experiment_cost
        end

      elsif rate == instances.published.order(:start_at).first.cost_in_temps
        # check if rate changed
        r = instances.published.order(:start_at).last.cost_in_temps * 0.9
        if r.round < 20
          20
        else
          r.round
        end
      else
        proposal.needed_for(instances.published.size)
      end
      # else
 #        if instances.published.size == 0
 #          Rate.get_current.experiment_cost
 #        else
 #          0
 #        end
 #      end
    end
  end

  def at_least_one_instance
    return unless instances.empty?
    errors.add(:base, "At least one instance of this experiment must exist.")
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
    return unless image.present? && image_changed?
    return unless image.file.exists?
    self.image_content_type = image.file.content_type
    self.image_size = image.file.size
    self.image_width, self.image_height = %x(identify -format "%wx%h" #{image.file.path}).split(/x/)
  end
end
