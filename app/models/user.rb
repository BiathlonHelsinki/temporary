class User < ActiveRecord::Base
  include PgSearch
  multisearchable against: %i[name about_me twitter_name username]
  rolify
  TEMP_EMAIL_PREFIX = 'change@me'
  TEMP_EMAIL_REGEX = /\Achange@me/

  # Include default devise modules.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :confirmable,
         :omniauthable, :validatable, authentication_keys: [:login]

  has_many :accounts
  has_many :authentications, dependent: :destroy
  # accepts_nested_attributes_for :authentications, :reject_if => proc { |attr| attr['username'].blank? }
  accepts_nested_attributes_for :accounts, reject_if: proc { |attr| attr['address'].blank? }
  acts_as_token_authenticatable
  validates_format_of :email, without: TEMP_EMAIL_REGEX, on: :update
  validates_uniqueness_of :email
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  # validates_format_of :username, with: /^[a-zA-Z0-9_\.]*$/, :multiline => true
  extend FriendlyId
  friendly_id :username, use: %i[slugged finders history]
  has_many :activities
  has_many :onetimers
  has_many :nfcs
  scope :untagged, -> { includes(:nfcs).where(nfcs: { user_id: nil }) }
  # has_many :event_users
  has_many :events, foreign_key: 'primary_sponsor_id'
  has_many :pledges
  has_many :proposals
  has_many :instances_users
  has_many :instances, through: :instances_users
  before_validation :copy_password
  mount_uploader :avatar, ImageUploader
  before_save :update_avatar_attributes
  after_create :add_to_activity_feed
  has_many :comments
  validates_presence_of :geth_pwd
  has_many :rsvps
  has_many :registrations
  has_many :userlinks
  has_many :userphotos
  has_many :userphotoslots
  has_one :survey

  def as_mentionable
    {
      created_at: created_at,
      id: id,
      slug: slug,
      route: 'users',
      image_url: avatar.url(:thumb).gsub(/development/, 'production'),
      name: display_name,
      updated_at: updated_at
    }
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(["lower(username) = :value OR lower(email) = :value", { value: login.downcase }]).first
    elsif conditions.has_key?(:username) || conditions.has_key?(:email)
      conditions[:email].downcase! if conditions[:email]
      where(conditions.to_hash).first
    end
  end

  attr_writer :login

  def login
    @login || username || email
  end

  def add_to_activity_feed
    Activity.create(item: self, description: 'joined', user: self)
  end

  def copy_password
    return if geth_pwd.present?
    self.geth_pwd = SecureRandom.hex(13)
  end

  # has_many :activities, as: :item

  def display_name
    if show_name == true
      if name == username
        name
      else
        "#{name} (#{username})"
      end
    else
      username
    end
  end

  def should_generate_new_friendly_id?
    username_changed?
  end

  def email_required?
    false
  end

  def all_activities
    [activities.temporary, Activity.temporary.where(item: self)].flatten.compact.uniq
  end

  def available_balance
    latest_balance - pending_pledges.sum(&:pledge)
  end

  def update_balance_from_blockchain
    api = BiathlonApi.new
    balance = api.api_get("/users/#{id}/get_balance")
    return unless balance
    return if balance.class == Hash
    latest_balance = balance.to_i
    latest_balance_checked_at = Time.now.to_i
    save(validate: false)
  end

  def award_points(event, points = 10)
    # check if user has ethereum account yet
    if accounts.empty?
      create_call = HTTParty.post(Figaro.env.dapp_address + '/create_account', body: { password: geth_pwd })
      accounts << Account.create(address: JSON.parse(create_call.body)['data'], primary_account: true) if JSON.parse(create_call.body)['data'].present?
    end
    # account is created in theory, so now let's do the transaction
    api = BidappApi.new
    transaction = api.mint(accounts.primary.first.address, points)
    accounts.primary.first.balance = accounts.primary.first.balance.to_i + points
    save(validate: false)
    # get transaction hash and add to activity feed. TODO: move to concern!!
    Activity.create(user: self, item: event, ethtransaction: Ethtransaction.find_by(txaddress: transaction), description: 'attended')
    true
  end

  def self.find_for_oauth(auth, signed_in_resource = nil)
     # Get the identity and user if they exist
    identity = Authentication.find_for_oauth(auth)

     # If a signed_in_resource is provided it always overrides the existing user
     # to prevent the identity being locked with accidentally created accounts.
     # Note that this may leave zombie accounts (with no associated identity) which
     # can be cleaned up at a later date.
    user = signed_in_resource || identity.user

     # Create the user if needed
    if user.nil?

      # Get the existing user by email if the provider gives us a verified email.
      # If no verified email was provided we assign a temporary email and ask the
      # user to verify it on the next step via UsersController.finish_signup
      email_is_verified = auth.info.email && (auth.info.verified || auth.info.verified_email)
      email = auth.info.email if email_is_verified
      user = User.where(email:).first if email

      # Create the user if it's a new registration
      if user.nil?
        user = User.new(
          name: auth.extra.raw_info.name,
          #username: auth.info.nickname || auth.uid,
          email: email || "#{TEMP_EMAIL_PREFIX}-#{auth.uid}-#{auth.provider}.com",
          password: Devise.friendly_token[0, 20]
        )
        user.skip_confirmation!
        user.save!
      end
    end

     # Associate the identity with the user if needed
    if identity.user != user
      identity.user = user
      identity.save!
    end
    user
  end

  def rsvpd?(instance)
    !rsvps.find_by(instance:).nil?
  end

  def registered?(instance)
    !registrations.find_by(instance:).nil?
  end

  def email_verified?
    email && email !~ TEMP_EMAIL_REGEX
  end

  def has_pledged?(item)
    pledges.where(item:).any?
  end

  def active_pledge?(proposal)
    pledges.unconverted.where(item: proposal).any?
  end

  def spent_pledges
    pledges.converted
  end

  def pending_pledges
    pledges.unconverted
  end

  def apply_omniauth(omniauth)
    if omniauth['provider'] == 'twitter'
      logger.warn(omniauth.inspect)
      self.username = omniauth['info']['nickname']
      self.name = omniauth['info']['name']
      name.strip!
      identifier = username

    elsif omniauth['provider'] == 'facebook'
      self.email = omniauth['info']['email'] if email.blank? || email =~ /change@me/
      self.username = omniauth['info']['name']
      self.name = omniauth['info']['name']
      name.strip!
      identifier = username
      # self.location = omniauth['extra']['user_hash']['location']['name'] if location.blank?
    elsif omniauth['provider'] == 'github'
      self.email = omniauth['info']['email'] if email.blank? || email =~ /change@me/
      self.username = omniauth['info']['nickname']
      self.name = omniauth['info']['name']
      name.strip!
      identifier = username
    elsif omniauth['provider'] == 'google_oauth2'
      self.email = omniauth['info']['email']
      self.name = omniauth['info']['name']
      self.username = omniauth['info']['email'].gsub(/@gmail\.com/, '')
      identifier = username
    end
    self.email = (omniauth['info']['email'].presence || "#{TEMP_EMAIL_PREFIX}-#{omniauth['uid']}-#{omniauth['provider']}.com") if email.blank?

    self.password = SecureRandom.hex(32) if password.blank? # generate random password to satisfy validations
    authentications.build(provider: omniauth['provider'], uid: omniauth['uid'], username: identifier)
  end

  def update_avatar_attributes
    return unless avatar.present? && avatar_changed?
    return unless avatar.file.exists?
    self.avatar = avatar.file.content_type
    self.avatar_size = avatar.file.size
    self.avatar_width, self.avatar_height = %x(identify -format "%wx%h" #{avatar.file.path}).split(/x/)
  end
end
