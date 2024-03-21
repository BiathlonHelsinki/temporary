class Post < ApplicationRecord
  belongs_to :user
  translates :title, :body
  extend FriendlyId
  friendly_id :title_en, use: %i[slugged finders]
  accepts_nested_attributes_for :translations, reject_if: proc { |x| x['title'].blank? || x['body'].blank? }
  before_save :update_image_attributes
  before_save :check_published
  mount_uploader :image, ImageUploader
  has_many :activities, as: :item, dependent: :destroy
  scope :published, -> { where(published: true) }
  scope :sticky, -> { where(sticky: true) }
  scope :not_sticky, -> { where("sticky is not true") }
  scope :by_era, ->(era_id) { where(era_id:) }
  belongs_to :postcategory

  def all_comments
    comments + comments.map(&:all_comments)
  end

  def total_comment_count
    all_comments.flatten.uniq.size
  end

  def name
    title
  end

  def root_comment
    self
  end

  def discussion
    comments
  end

  def title_en
    title(:en)
  end

  def category_text
    'news'
  end

  def check_published
    return unless published == true
    self.published_at ||= Time.now
  end

  def feed_date
    published_at
  end

  def update_image_attributes
    return unless image.present? && image_changed?
    return unless image.file.exists?
    self.image_content_type = image.file.content_type
    self.image_size = image.file.size
    self.image_width, self.image_height = %x(identify -format "%wx%h" #{image.file.path}).split(/x/)
  end

  private

  def should_generate_new_friendly_id?
    changed?
  end
end
