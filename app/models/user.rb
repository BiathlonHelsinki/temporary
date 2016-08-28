class User < ActiveRecord::Base
  rolify
  TEMP_EMAIL_PREFIX = 'change@me'
  TEMP_EMAIL_REGEX = /\Achange@me/
  
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :trackable,
          :omniauthable #, :confirmable
  has_many :accounts
  has_many :authentications, :dependent => :destroy
  # accepts_nested_attributes_for :authentications, :reject_if => proc { |attr| attr['username'].blank? }
  accepts_nested_attributes_for :accounts, reject_if: proc {|attr| attr['address'].blank? }
  # acts_as_token_authenticatable
  validates_format_of :email, :without => TEMP_EMAIL_REGEX, on: :update
  extend FriendlyId
  friendly_id :username , :use => [ :slugged, :finders ] # :history]
  has_many :activities
  has_many :onetimers
  has_many :nfcs
  has_and_belongs_to_many :experiments  
  scope :untagged, -> () { includes(:nfcs).where( nfcs: {user_id: nil}) }
  has_many :event_users
  has_many :experiments, through: :events_users, foreign_key: 'event_id'
  has_many :pledges
  has_many :proposals
  has_many :instances_users
  has_many :instances, through: :instances_users
  before_create :copy_password
  
  def copy_password
    geth_pwd = encrypted_password
  end
  
  # has_many :activities, as: :item
  
  def email_required?
    false
  end
  
  def all_activities
    [activities, Activity.where(item: self)].flatten.compact
  end
  
  def available_balance
    latest_balance - pending_pledges.sum(&:pledge)      
  end
  
  def update_balance_from_blockchain
    api = BiathlonApi.new
    balance = api.api_get("/users/#{id}/get_balance")
    if balance
      latest_balance = balance.to_i
      latest_balance_checked_at = Time.now.to_i
      save(validate: false)
    end
    
  end
  
  def award_points(event, points = 10)

    # check if user has ethereum account yet
    if accounts.empty?
      create_call = HTTParty.post(Figaro.env.dapp_address + '/create_account', body: {password: self.geth_pwd})
      unless JSON.parse(create_call.body)['data'].blank?
        accounts << Account.create(address: JSON.parse(create_call.body)['data'], primary_account: true)
      end
    end
    # account is created in theory, so now let's do the transaction
    api = BidappApi.new
    transaction = api.mint(self.accounts.primary.first.address, points)
    accounts.primary.first.balance = accounts.primary.first.balance.to_i + points
    save(validate: false)
    # get transaction hash and add to activity feed. TODO: move to concern!!
    Activity.create(user: self, item: event, ethtransaction: Ethtransaction.find_by(txaddress: transaction), description: 'attended')
    return true
  end

  def self.find_for_oauth(auth, signed_in_resource = nil)

     # Get the identity and user if they exist
     identity = Authentication.find_for_oauth(auth)

     # If a signed_in_resource is provided it always overrides the existing user
     # to prevent the identity being locked with accidentally created accounts.
     # Note that this may leave zombie accounts (with no associated identity) which
     # can be cleaned up at a later date.
     user = signed_in_resource ? signed_in_resource : identity.user

     # Create the user if needed
     if user.nil?

       # Get the existing user by email if the provider gives us a verified email.
       # If no verified email was provided we assign a temporary email and ask the
       # user to verify it on the next step via UsersController.finish_signup
       email_is_verified = auth.info.email && (auth.info.verified || auth.info.verified_email)
       email = auth.info.email if email_is_verified
       user = User.where(:email => email).first if email

       # Create the user if it's a new registration
       if user.nil?
         user = User.new(
           name: auth.extra.raw_info.name,
           #username: auth.info.nickname || auth.uid,
           email: email ? email : "#{TEMP_EMAIL_PREFIX}-#{auth.uid}-#{auth.provider}.com",
           password: Devise.friendly_token[0,20]
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

   def email_verified?
     self.email && self.email !~ TEMP_EMAIL_REGEX
   end
   
   def has_pledged?(proposal)
     pledges.where(item: proposal).any?
   end
     
   def pending_pledges
     pledges.to_a.delete_if{|x| x.converted == 1}
   end
   
  def apply_omniauth(omniauth)
    if omniauth['provider'] == 'twitter'
      logger.warn(omniauth.inspect)
      self.username = omniauth['info']['nickname']
      self.name = omniauth['info']['name']
      self.name.strip!
      identifier = self.username

    elsif omniauth['provider'] == 'facebook'
      self.email = omniauth['info']['email'] if email.blank? || email =~ /change@me/
      self.username = omniauth['info']['name']
      self.name = omniauth['info']['name'] 
      self.name.strip!
      identifier = self.username
      # self.location = omniauth['extra']['user_hash']['location']['name'] if location.blank?
    elsif omniauth['provider'] == 'google_oauth2'
      self.email = omniauth['info']['email'] 
      self.name = omniauth['info']['name']
      self.username = omniauth['info']['email']
      identifier = self.username
    end
    if email.blank?
      if omniauth['info']['email'].blank?
        self.email = "#{TEMP_EMAIL_PREFIX}-#{omniauth['uid']}-#{omniauth['provider']}.com"
      else
        self.email = omniauth['info']['email']
      end
    end
    
    self.password = SecureRandom.hex(32) if password.blank?  # generate random password to satisfy validations
    authentications.build(:provider => omniauth['provider'], :uid => omniauth['uid'], :username => identifier)
  end
  
  
end
