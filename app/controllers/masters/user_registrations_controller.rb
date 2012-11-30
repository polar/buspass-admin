class Masters::UserRegistrationsController < Masters::MasterBaseController

  rescue_from Exception, :with => :rescue_master_error_page

  def new
    get_master_context
    @authentication = Authentication.find session[:user_oauth_id]
    if @authentication
      user = User.find_by_authentication_id(@authentication.id)
      if user
        if params[:mobile]
          signin(user)
          redirect_to "busme://oauthresponse?access_token=#{current_user.get_access_token}&master=#{@master.slug}"
        else
          redirect_to edit_master_user_registration_path(@master, user), :notice => "edit"
        end
      else
        @user = User.new()
        @user.name = @authentication.name
        @user.email = @authentication.last_info["email"]
        @user.master = @master
        if params[:mobile]
          render :new_mobile
        else
          render
        end
      end
    else
      if params[:mobile]
        redirect_to master_mobile_user_sign_in_path(@master), :notice => "You need to authenticate first."
      else
        redirect_to user_sign_in_path(:master_id => @master.id), :notice => "You need to authenticate first."
      end
    end
  end

  def new_mobile
    get_master_context
    @authentication = Authentication.find session[:user_oauth_id]
    if @authentication
      user = User.find_by_authentication_id(@authentication.id)
      if user
        signin(user)
        redirect_to "busme://oauthresponse?access_token=#{current_user.get_access_token}&master=#{@master.slug}"
      else
        @user       = User.new()
        @user.name  = @authentication.name
        @user.email = @authentication.last_info["email"]
        @user.master = @master
      end
    else
      redirect_to master_mobile_user_sign_in_path(:master_id => @master.id), :notice => "You need to authenticate first."
    end
  end

  def edit
    get_master_context
    authenticate_user!

    @user = current_user
    @authentication = @user.authentications.find session[:user_oauth_id]
    @authentications = @user.authentications - [@authentication]
    @providers = BuspassAdmin::Application.oauth_providers - @user.authentications.map {|a| a.provider.to_s }
    @oauth_options = "?tpauth=amend_user&master_id=#{@master.id}&user_auth=#{session[:session_id]}&failure_path=#{edit_master_user_registration_path(@master, @user)}"
  end

  #
  # This gets called from a redirect from new_registration
  #
  def create
    get_master_context
    tpauth = Authentication.find session[:user_oauth_id]
    if tpauth
      @user = User.new(params[:user])
      @user.authentications << tpauth
      @user.master = @master
      if @user.save
        session[:user_id] = @user.id
        redirect_to edit_master_user_registration_path(@master, @user), :notice => "Signed In!"
      else
        render :new
      end
    else
      redirect_to master_user_sign_in_path( @master), "You need to authenticate first."
    end
  end

  #
  # This gets called from a redirect from new_registration
  #
  def create_mobile
    get_master_context
    tpauth = Authentication.find session[:user_oauth_id]
    if tpauth
      @user = User.new(params[:user])
      @user.authentications << tpauth
      @user.master = @master
      if @user.save
        session[:user_id] = @user.id
        redirect_to "busme://oauthresponse?access_token=#{current_user.get_access_token}&master=#{@master.slug}"
      else
        render edit_master_mobile_user_registrations_path(@master), :error => "Fix"
      end
    else
      redirect_to master_mobile_user_sign_in_path(@master), :notice => "You need to authenticate first."
    end
  end

  #
  # This gets called from a redirect from edit_registration
  def update
    get_master_context
    authenticate_user!
    tpauth = Authentication.find session[:user_oauth_id]
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