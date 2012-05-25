class User
  include MongoMapper::Document

  # tango_user

#  plugin MongoMapper::Devise

  class << self
    Devise::Models.config(self, :email_regexp, :password_length)
  end

  # Include default devise modules. Others available are:
  # :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable, :validatable
  devise :database_authenticatable, :registerable, :token_authenticatable,
         :recoverable, :rememberable, :trackable

  belongs_to :master

  ## Database authenticatable
  key :email,              String, :null => false, :default => ""
  key :encrypted_password, String, :null => false, :default => ""

  ## Recoverable
  key :reset_password_token,   String
  key :reset_password_sent_at, Time

  ## Rememberable
  key :remember_created_at, Time

  ## Trackable
  key :sign_in_count,      Integer, :default => 0
  key :current_sign_in_at, Time
  key :last_sign_in_at,    Time
  key :current_sign_in_ip, String
  key :last_sign_in_ip,    String

  ## Encryptable
  # key :password_salt, String

  ## Confirmable
  # key :confirmation_token,   String
  # key :confirmed_at,         Time
  # key :confirmation_sent_at, Time
  # key :unconfirmed_email,    String # Only if using reconfirmable

  ## Lockable
  # key :failed_attempts, Integer, :default => 0 # Only if lock strategy is :failed_attempts
  # key :unlock_token,    String # Only if unlock strategy is :email or :both
  # key :locked_at,       Time

  ## Token authenticatable
  # key :authentication_token, String

  ## Invitable
  # key :invitation_token, String

  key :name, String
  # Array of String
  key :role_symbols, Array, :default => []

  validates_presence_of :name

  attr_accessible :name, :email, :password, :password_confirmation, :remember_me
  attr_accessible :role_symbols
  attr_accessible :encrypted_password, :master_id

  validates_presence_of   :email, :if => :email_required?
  validates_uniqueness_of :email, :allow_blank => true, :if => :email_changed?, :scope => :master_id
  validates_format_of     :email, :with  => email_regexp, :allow_blank => true, :if => :email_changed?

  validates_presence_of     :password, :if => :password_required?
  validates_confirmation_of :password, :if => :password_required?
  validates_length_of       :password, :within => password_length, :allow_blank => true

  # Checks whether a password is needed or not. For validations only.
  # Passwords are always required if it's a new record, or if the password
  # or confirmation are being set somewhere.
  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

  def email_required?
    true
  end

  def self.find_for_database_authentication(conditions)
    super
  end

  def initialize(attrs = {})
    super
    # This little hack allows us to assign encrypted_password while making a new
    # User.non-empty
  end

  POSSIBLE_ROLES =  ["customer", "driver"]

  def possible_roles
    return POSSIBLE_ROLES
  end

  # TODO: Important. The last role in the list is the only significant one.
  def add_roles(roles)
    if !roles.is_a? Array
      roles = [roles]
    end
    rs = (self.role_symbols + roles.map {|x| x.to_s}).uniq
    self.role_symbols = rs
  end

  def add_roles!(roles)
    add_roles(roles)
    save!
  end

  def remove_roles(roles)
    if !roles.is_a? Array
      roles = [roles]
    end
    rs = (self.role_symbols) - (roles.map {|x| x.to_s})
  end

  def remove_roles!(roles)
    remove_roles(roles)
    save!
  end

  # This needs an optional argument. Who knew?
  def roles_list(role = nil)
    self.role_symbols
  end

  def has_role?(role)
    self.role_symbols.include?(role.to_s)
  end

  ##
  # This method allows us to programmatically disable empty password validation
  # by making the @password instance variable non-empty.
  #
  # Purpose:
  # We cannot skip this check on new records without rewriting password_required?. Even
  # so, we would have to build a method to handle the check. We can skip the validate_presence_of
  # check on :password just by assigning the @password instance variable to something that is not empty.
  # We cannot subvert this check by using password= because that alters the encrypted_password, and we want
  # to be able to assign a new user without having to go through the password process.
  #
  #noinspection RubyInstanceMethodNamingConvention
  def disable_empty_password_validation()
    @password = "non-empty"
  end
end