class Comment < ApplicationRecord
  include PgSearch
  multisearchable against: :content
  belongs_to :item, polymorphic: true, touch: true
  belongs_to :user
  mount_uploader :image, ImageUploader
  mount_uploader :attachment, AttachmentUploader
  validates_presence_of :user_id, :item_id, :item_type, :content
  before_save :update_image_attributes, :update_attachment_attributes
  after_create :update_activity_feed
  after_create -> {
    ActiveRecord::Base.connection.execute("UPDATE proposals SET updated_at=now() WHERE id=#{item.id}") if item.class == Proposal
  }
  scope :frontpage, -> { where(frontpage: true) }
  scope :temporary, -> { where("id < 160") }

  def update_activity_feed
    Activity.create(user: user, item: item, description: "commented_on", addition: 0)
    matches = content.scan(%r{rel="/users/(\d*)"})
    return if matches.empty?
    matches.flatten.each do |uu|
      u = User.find(uu.to_i)
      Activity.create(user: u, description: 'was_mentioned_by', item: user, extra: item, extra_info: 'in_a_comment_on', addition: 0) unless u.nil?
    end
  end

  def all_comments
    comments + comments.map(&:all_comments)
  end

  def discussion
    comments
  end

  delegate :name, to: :root_comment

  def root_comment
    if item.class == Comment
      item.root_comment
    else
      item
    end
  end

  def feed_date
    created_at
  end

  def title
    item.name
  end

  def body
    content_linked
  end

  def content_linked
    content.gsub(/href="#"/, '').gsub(/\srel="/, ' href="')
    # content.gsub(/href="(.*)#"/, '').gsub(/\srel="/, ' href="')
  end

  def update_image_attributes
    return unless image.present? && image_changed?
    return unless image.file.exists?
    self.image_content_type = image.file.content_type
    self.image_size = image.file.size
    self.image_width, self.image_height = %x(identify -format "%wx%h" #{image.file.path}).split(/x/)
  end

  def update_attachment_attributes
    return unless attachment.present? && attachment_changed?
    return unless attachment.file.exists?
    self.attachment_content_type = attachment.file.content_type
    self.attachment_size = attachment.file.size
  end
end
