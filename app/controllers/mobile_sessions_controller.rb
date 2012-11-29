class MobileSessionsController < ApplicationController
  layout   "mobile"

  def app_sign_in
    reset_session
    get_context
    token = params[:access_token]
    user = User.where(:access_token => token).first
    if user
      signin(user)
      render :nothing => true, :status => 200
    else
      render :nothing => true, :status => 403
    end
  end

  #
  # Set up a new User Session. The @master should be assigned.
  #
  def new_user
    get_context
    # We are going to auth a general user. We indicate that in the session
    if false && current_user
      redirect_to "busme://oauthresponse?access_token=#{current_user.get_access_token}&master=#{@master.slug}"
    else
      @providers = BuspassAdmin::Application.oauth_providers
      session[:master_id] = @master.id
      @options   = "?tpauth=mobile_user&master_id=#{@master.id}&user_auth=#{session[:session_id]}&failure_path=#{new_user_mobile_sessions_path(:master_id => @master.id)}"
    end

  end

  def get_context
    #TODO: Fix parsing of :siteslug in face of api.syracuse.busme.us in routes.rb
    #                          |-------------------^^^^^^^^
    # Ex. http://busme.us/auth/google?master_id=22342342234
    @master_id = params[:master_id] || params[:siteslug]
    @master = Master.find(@master_id) || Master.find_by_slug(@master_id)
    if !@master
      # Ex. http://syracuse.busme.us/auth/google
      #TODO: Fix parsing of :siteslug in face of api.syracuse.busme.us here
      basehost_regex =base_host.gsub(".", "\\.")
      match = /^([a-zA-Z0-9\-\\.]+)\.#{basehost_regex}$/.match(request.host)
      if match
        slug = match[1]
        @master = Master.where(:slug => slug).first
      end
    end
    if !@master
      @master = Master.find(session[:master_id])
    end
  end
end