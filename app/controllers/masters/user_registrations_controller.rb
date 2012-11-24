class Masters::UserRegistrationsController < Masters::MasterBaseController

  def new
    get_master_context
    @authentication = Authentication.find session[:tpauth_id]
    if @authentication
      user = User.find_by_authentication_id(@authentication.id)
      if user
        redirect_to edit_registration_master_users_path(:master_id => @master.id), :notice => "edit"
      else
        @user = User.new()
        @user.name = @authentication.name
        @user.email = @authentication.last_info["email"]
        @user.master = @master
      end
    else
      redirect_to user_sign_in_path(:master_id => @master.id), :notice => "You need to authenticate first."
    end
  end

  def edit
    get_master_context
    authenticate_user!

    @user = current_user
    @authentication = @user.authentications.find session[:tpauth_id]
    @authentications = @user.authentications - [@authentication]
    @providers = BuspassAdmin::Application.oauth_providers - @user.authentications.map {|a| a.provider.to_s }
    @oauth_options = "?tpauth=amend_user&master_id=#{@master.id}&user_auth=#{session[:session_id]}&failure_path=#{edit_master_user_registration_path(@master, @user)}"


    # We put this in the session in case the user adds an authentication.
    session[:tpauth] = :amend_user
  end

  #
  # This gets called from a redirect from new_registration
  #
  def create
    get_master_context
    tpauth = Authentication.find session[:tpauth_id]
    if tpauth
      @user = User.new(params[:user])
      @user.authentications << tpauth
      @user.master = @master
      @user.save
      session[:user_id] = @user.id
      redirect_to edit_master_user_registration_path(@master, @user), :notice => "Signed In!"
    else
      redirect_to master_user_sign_in_path( @master), "You need to authenticate first."
    end
  end

  #
  # This gets called from a redirect from edit_registration
  def update
    get_master_context
    authenticate_user!
    # We put this in the session in case the user adds an authentication.
    session[:tpauth] = nil
    tpauth = Authentication.find session[:tpauth_id]
    if tpauth
      @user = current_user
      @user.update_attributes(params[:user])
      @user.authentications << tpauth
      @user.save
      redirect_to edit_master_user_registration_path(@master, @user), :notice => "Account Updated!"
    else
      redirect_to master_user_sign_in_path(@master), "You need to authenticate first."
    end
  end


end