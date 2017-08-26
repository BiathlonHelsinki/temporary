class Event < ApplicationRecord
  self.table_name = "events"
  include PgSearch
  belongs_to :place
  belongs_to :primary_sponsor, class_name: 'User'
  belongs_to :secondary_sponsor, class_name: 'User'
  translates :name, :description, :fallbacks_for_empty_translations => true
  accepts_nested_attributes_for :translations, :reject_if => proc {|x| x['name'].blank? && x['description'].blank? }
  belongs_to :place
  has_many :notifications, as: :item
  has_many :activities, -> { where item_type: "Event"}, foreign_key: :item_id, foreign_type: :item_type,  dependent: :destroy
  has_many :pledges, -> { where item_type: "Event"}, foreign_key: :item_id, foreign_type: :item_type,   dependent: :destroy
  resourcify
  belongs_to :proposal

  extend FriendlyId
  friendly_id :name_en , :use => [ :slugged, :finders ] # :history]
  mount_uploader :image, ImageUploader
  process_in_background :image
  validates_presence_of :place_id, :start_at, :primary_sponsor_id, :sequence, :proposal_id
  validate :name_present_in_at_least_one_locale
  before_save :update_image_attributes
  has_many :comments, as: :item, :dependent => :destroy
  

  
  acts_as_nested_set
  has_many :instances, foreign_key: 'event_id', dependent: :destroy

  before_validation :make_first_instance
  validate :at_least_one_instance
  validates_uniqueness_of :sequence
  
  scope :published, -> () { where(published: true) }
  scope :has_events_on, -> (*args) { where(['published is true and (date(start_at) = ? OR (end_at is not null AND (date(start_at) <= ? AND date(end_at) >= ?)))', args.first, args.first, args.first] )}
  scope :between, -> (start_time, end_time) { 
    where( [ "(start_at >= ?  AND  end_at <= ?) OR ( start_at >= ? AND end_at <= ? ) OR (start_at >= ? AND start_at <= ?)  OR (start_at < ? AND end_at > ? )",
    start_time, end_time, start_time, end_time, start_time, end_time, start_time, end_time])
  }
  
  
  def as_mentionable
    {
      created_at: self.created_at,
      id: self.id,
      slug: self.slug,
      image_url: self.image.url(:thumb).gsub(/development/, 'production'),
      name:  self.name,
      route: 'experiments',
      updated_at: self.updated_at
    }
  end
  
  def discussion
    comments
  end
  
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
  
  def is_valid?
    true
  end
  
  def has_enough?
    pledges.unconverted.sum(&:pledge) >= needed_for_next
  end
  
  def pledged
    pledges.sum{|x| x.pledge.to_i}
  end
  
  def remaining_pledges
    pledges.unconverted.sum(&:pledge)
  end
  def recurs?
    proposal.recurs?
  end
  
  def published_instances
    instances.published.size
  end
  
  def maximum_pledgeable(user)
    if pledges.map(&:user).include?(user)  # user has already pledged
      if has_enough?
        if recurs?
          if intended_sessions == 0
            user.available_balance + (pledges.unconverted.find_by(user: user).nil? ? 0 :  pledges.unconverted.find_by(user: user).pledge)
          else
            (user.available_balance + (pledges.unconverted.find_by(user: user).nil? ? 0 : pledges.unconverted.find_by(user: user).pledge)) > cumulative_needed_for(intended_sessions) ? cumulative_needed_for(intended_sessions) : (user.available_balance + pledges.unconverted.find_by(user: user).pledge) 
          end
        else
          pledges.unconverted.find_by(user: user).pledge
        end
      
      elsif pledges.map(&:user).size == 1
        Rate.get_current.experiment_cost - 1
      else
        [proposal.cumulative_needed_for(intended_sessions).to_i, user.available_balance].max
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
          total_needed_with_recurrence - 1
        else
          total_needed_with_recurrence
        end
      else
        total_needed_with_recurrence
      end
    end
    
  end
  
  def number_that_can_be_scheduled
    proposal.number_that_can_be_scheduled
  end
  def intended_sessions
    proposal.intended_sessions
  end
  
  def self.schedulable
    includes(:pledges).to_a.delete_if{|x| x.remaining_pledges == 0}.delete_if{ |x| x.remaining_pledges == 0  }.sort_by(&:name)
  end
  
  def total_needed_with_recurrence
    proposal.total_needed_with_recurrence
  end
  
  
  def dormant?
    if created_at >= 3.months.ago 
      return false
    else
      if (pledges.empty? || pledges.last.created_at < 3.months.ago) && (comments.empty? || comments.last.created_at < 3.months.ago) && ( instances.published.empty? || instances.published.last.start_at < 3.months.ago )
        return true
      end
    end
  end
  
  def last_activity
    [created_at, (pledges.empty? ? nil : pledges.last.created_at ), (comments.empty? ? nil : comments.last.created_at ), (instances.published.empty? ? nil : instances.published.order(:start_at).last.start_at)].compact.max
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
        
        else
          # check if rate changed
          if rate == instances.published.order(:start_at).first.cost_in_temps        
            r = instances.published.order(:start_at).last.cost_in_temps * 0.9
            if r.round < 20
              20
            else
              r.round
            end
          else
            proposal.needed_for(instances.published.size)
          end
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