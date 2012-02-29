class Muni::MuniAdmin
    include MongoMapper::Document

   # tango_user

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

    key :role_symbols, Array, :default => []

    validates_presence_of :name
    validates_uniqueness_of :email, :case_sensitive => false
    attr_accessible :name, :email, :password, :password_confirmation, :remember_me
    attr_accessible :role_symbols
    attr_accessible :encrypted_password

    def initialize(attrs = {})
        super
        # This little hack allows us to assign encrypted_password while making a new
        # User.non-empty
    end

    # TODO: Important. The last role in the list is the only significant one.
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

    # This needs an optional argument. Who knew?
    def roles_list(role = nil)
        role_symbols
    end

    def has_role?(role)
        role_symbols.include?(role.to_s)
    end

    ##
    # This allows us to programmatically disable empty password validation
    # by making the @password instance variable non-empty.
    #
    # Purpose:
    # We cannot skip this check on new records without rewriting password_required?. Even
    # so, we would have to build a method to handle the check. We can skip the validate_presence_of
    # check on :password just by assigning the @password instance variable to something that is not empty.
    # We cannot subsert this check by using password= because that alters the encrypted_password, and we want
    # to be able to assign a new user without having to go through the password process.
    #
    #noinspection RubyInstanceMethodNamingConvention
    def disable_empty_password_validation()
        @password = "non-empty"
    end
end