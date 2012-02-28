class Admin
    include MongoMapper::Document

    tango_user

  plugin MongoMapper::Devise

  # Include default devise modules. Others available are:
  # :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :token_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable

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
  key :name, String
  validates_presence_of :name
  validates_uniqueness_of :email, :case_sensitive => false
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me
  attr_accessible :encrypted_password

    key :role_symbols, Array, :default => []

    def add_roles(roles)
      if !roles.is_a? Array
        roles = [roles]
      end
      rs = (role_symbols + roles).uniq
      role_symbols = rs
    end

    def add_roles!(roles)
      add_roles(roles)
      save!
    end

    def remove_roles(roles)
      if !roles.is_a? Array
        roles = [roles]
      end
      rs = (role_symbols) - roles
    end

    def remove_roles!(roles)
      remove_roles(roles)
      save!
    end

    def roles_list
      role_symbols
    end

    def has_role?(role)
      roles.include?(role.to_s)
    end

end

