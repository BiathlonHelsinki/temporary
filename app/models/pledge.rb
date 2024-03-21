class Pledge < ApplicationRecord
  belongs_to :item, polymorphic: true, touch: true
  belongs_to :event, foreign_key: :item_id, class_name: 'Event'
  belongs_to :proposal, foreign_key: :item_id, class_name: 'Proposal'
  has_many :activities, as: :item
  belongs_to :user
  after_save :update_activity_feed
  before_destroy :withdraw_activity
  validate :check_balance
  after_save :notify_if_enough
  validates_numericality_of :pledge, greater_than_or_equal_to: 0
  acts_as_paranoid
  validate :one_per_user
  belongs_to :instance

  scope :unconverted, -> { where('converted = 0 OR converted is null') }
  scope :converted, -> { where(converted: true) }

  def check_balance
    user.update_balance_from_blockchain
    return unless pledge < 1 || pledge > user.latest_balance
    errors.add(:pledge, 'You cannot pledge this amount.')
  end

  def one_per_user
    return if item.pledges.where(user: user, converted: false).to_a.delete_if { |x| x == self }.empty?
    errors.add(:user, 'You have already pledged to this. Please edit your pledge.')
  end

  def content_linked
    comment.gsub('href="#"', '').gsub(/\srel="/, ' href="')
  end

  def content
    comment
  end

  def name
    item.nil? ? ' deleted proposal ' : item.name
  end

  def notify_if_enough
    return unless (item.pledged + pledge) >= Rate.get_current.experiment_cost
    return unless item.class == Proposal
    return unless item.notified != true

    begin
      ProposalMailer.proposal_for_review(item).deliver
      item.update_attribute(:notified, true)
    rescue StandardError
      item.notified = false
    end
  end

  def image?
    false
  end

  def attachment?
    false
  end

  def update_activity_feed
    if created_at == updated_at
      # assume it's new
      Activity.create(user_id: user_id, item: self, description: "pledged_to", numerical_value: pledge, extra_info: pledge, addition: 0)
    else
      Activity.create(user: user, item: self, description: "edited_their_pledge_to", extra_info: pledge, addition: 0)
    end
    return unless item.class == Proposal
    item.update_column_caches
    item.save
  end

  def withdraw_activity
    item.comments << Comment.create(user: user, content: "Pledge of #{pledge}#{ENV['currency_symbol']} withdrawn.", systemflag: true)
    Activity.create(user: user, item: item, description: "withdrew_a_pledge", extra_info: "#{pledge}", addition: 0)
  end
end
