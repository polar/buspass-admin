class SessionsController < ApplicationController

  #
  # This gets called from /auth/:provider/callback
  #
  def create
    get_context
    if params[:provider] == "facebook"
      state_urldata = params[:state]
      state_data = CGI::unescape(state_urldata)
      state = JSON.parse(state_data)
      params.merge! state
    end
    if params[:tpauth].nil?
      redirect_to root_path, :notice => "Invalid Authentication Request."
      return
    end

    # This parameter variable is set by /edit_[customer, muni_admin, user, admin]
    case params[:tpauth].to_sym
      when :mobile_user
        if params[:user_auth] == session[:session_id]
          if User.find(session[:user_id])
            # We are already signed in for some reason. Out of sync calls by another page. Just amend.
            amend_mobile_user()
          else
            create_mobile_user()
          end
        else
          redirect_to params[:failure_path] || root_path, :notice => "Session Expired or Invalid. Please sign in."
        end

      # From sessions#new_customer
      when :customer
        if params[:customer_auth] == session[:session_id]
          if Customer.find(session[:customer_id])
            # We are already signed in for some reason. Out of sync calls by another page. Just amend.
            amend_customer()
          else
            create_customer()
          end
        else
          redirect_to params[:failure_path] || root_path, :notice => "Session Expired or Invalid. Please sign in."
        end
      when :muni_admin
        if params[:muni_admin_auth] == session[:session_id]
          if MuniAdmin.find(session[:muni_admin_id])
            # We are already signed in for some reason. Out of sync calls by another page. Just amend.
            amend_muni_admin()
          else
            create_muni_admin()
          end
        else
          redirect_to params[:failure_path] || root_path, :notice => "Session Expired or Invalid. Please sign in."
        end
      when :user
        if params[:user_auth] == session[:session_id]
          if User.find(session[:user_id])
            # We are already signed in for some reason. Out of sync calls by another page. Just amend.
            amend_user()
          else
            create_user()
          end
        else
          redirect_to params[:failure_path] || root_path, :notice => "Session Expired or Invalid. Please sign in."
        end
      when :amend_customer
        if params[:customer_auth] == session[:session_id]
          if Customer.find(session[:customer_id])
            amend_customer()
          else
            # Hmm, we are no longer signed in or user has been deleted. Just try to create.
            create_customer()
          end
        else
          redirect_to params[:failure_path] || root_path, :notice => "Session Expired or Invalid. Please sign in."
        end
      when :amend_muni_admin
        if params[:muni_admin_auth] == session[:session_id]
          if MuniAdmin.find(session[:muni_admin_id])
            amend_muni_admin()
          else
            # Hmm, we are no longer signed in or user has been deleted. Just try to create.
            create_muni_admin()
          end
        else
          redirect_to params[:failure_path] || root_path, :notice => "Session Expired or Invalid. Please sign in."
        end
      when :amend_user
        if params[:user_auth] == session[:session_id]
          if User.find(session[:user_id])
            amend_user()
          else
            # Hmm, we are no longer signed in or user has been deleted. Just try to create.
            create_user()
          end
        else
          redirect_to params[:failure_path] || root_path, :notice => "Session Expired or Invalid. Please sign in."
        end
      else
        redirect_to params[:failure_path] || root_path, :notice => "Session Expired or Invalid. Please sign in."

    end
  end

  #
  # Set up a new Customer Session
  # There is no @master for Customer.
  #
  def new_customer
    # We are going to auth a customer. We indicate that in the session
    if current_customer
      redirect_to edit_customer_registration_path(current_customer), :notice => "You are already signed in."
    else
      @providers = BuspassAdmin::Application.oauth_providers
      session[:tpauth] = :customer
      @options = "?tpauth=customer&customer_auth=#{session[:session_id]}&failure_path=#{root_path}"
      # We will render new_customer and then that will redirect to sessions#create on /auth/;provider/callback
      state_data  = { :tpauth => :customer, :customer_auth => session[:session_id], :failure_path => root_path }
      state_urldata = CGI::escape(state_data.to_json)
      @fb_options = "?state=#{state_urldata}"
    end
  end

  def destroy_customer
    session[:customer_id] = nil
    session[:customer_oauth_id] = nil
    redirect_to root_path, :notice => "Signed out!"
  end

  #
  # Set up a new MuniAdmin Session. The @master should be assigned.
  #
  def new_muni_admin
    get_context
    # We are going to auth a muni_admin. We indicate that in the session
    if current_muni_admin
      redirect_to edit_master_muni_admin_registration_path(current_muni_admin.master, current_muni_admin), :notice => "You are already signed in."
    else
      @providers = BuspassAdmin::Application.oauth_providers
      session[:master_id] = @master.id
      @options = "?tpauth=muni_admin&master_id=#{@master.id}&muni_admin_auth=#{session[:session_id]}&failure_path=#{new_muni_admin_sessions_path(:master_id => @master.id)}"

      state_data = { :tpauth => :muni_admin, :master_id => @master.id.to_s, :muni_admin_auth => session[:session_id],:failure_path => new_muni_admin_sessions_path(:master_id => @master.id) }
      state_urldata = CGI::escape(state_data.to_json)
      @fb_options = "?state=#{state_urldata}"
    end

  end

  def destroy_muni_admin
    if current_muni_admin
      master = current_muni_admin.master
      session[:muni_admin_id] = nil
      redirect_to master_path(master), :notice => "Signed out!"
    else
      get_context
      if @master
        redirect_to master_path(@master), :notice => "You weren't signed in."
      else
        flash[:notice] = "You signed out, but we don't know where from."
        render "public/404.html", :status => 404
      end
    end
  end

  #
  # Set up a new User Session. The @master should be assigned.
  #
  def new_user
    get_context
    # We are going to auth a general user. We indicate that in the session
    if current_user
      redirect_to edit_master_user_registration_path(current_user.master, current_user), :notice => "You are already signed in."
    else
      @providers       = BuspassAdmin::Application.oauth_providers
      session[:master_id] = @master.id
      @options = "?tpauth=user&master_id=#{@master.id}&user_auth=#{session[:session_id]}&failure_path=#{new_user_sessions_path(:master_id => @master.id)}"
      state_data = { :tpauth => :user, :master_id => @master.id.to_s, :user_auth => session[:session_id], :failure_path => new_user_sessions_path(:master_id => @master.id) }
      state_urldata = CGI::escape(state_data.to_json)
      @fb_options = "?state=#{state_urldata}"
    end

  end

  def destroy_user
    if current_user
      master              = current_user.master
      session[:user_id] = nil
      session[:user_oauth_id] = nil
      redirect_to master_active_path(master), :notice => "Signed out!"
    else
      # Attempt to get the master
      get_context
      if @master
        redirect_to master_active_path(master), :notice => "Signed out!"
      else
        flash[:notice] = "You signed out, but we don't know where from."
        render "public/404.html", :status => 404
      end
    end
  end
  
  private

  #
  # Create a Customer session. There is no current Customer session, or an invalid one.
  #
  def create_customer
    session[:customer_id] = nil
    session[:customer_oauth_id] = nil

    auth  = request.env["omniauth.auth"]
    # We should only have one of these.
    oauths = Authentication.where(:provider => auth["provider"],
                                  :uid => auth["uid"],
                                  :customer_id.ne => nil,
                                  :master_id => nil).order("created_at desc").all
    oauth = oauths.first
    oauths.drop(1).each do |oa|
      logger.error "sessions#create_customer: Removing extra authentications"
      oa.destroy()
    end
    if oauth
      session[:customer_oauth_id] = oauth.id
      cust = oauth.customer
      if cust != nil
        session[:customer_id] = cust.id
        oauth.last_info = auth["info"]
        oauth.save
        redirect_to my_index_websites_path, :notice => "Signed in!"
      else
        redirect_to new_customer_registration_path, :notice => "Could not find you. Please create an account."
      end
    else
      oauth = Authentication.create_with_omniauth(auth)
      session[:customer_oauth_id] = oauth.id
      redirect_to new_customer_registration_path, :notice => "Need to create an account."
    end
  end

  #
  # This when we already have a valid customer session.
  #
  def amend_customer
    # we should have a current customer.
    cust = current_customer
    if (cust)
      auth  = request.env["omniauth.auth"]
      # We should only have one of these.
      oauths = Authentication.where(:provider => auth["provider"],
                                    :uid => auth["uid"],
                                    :customer_id.ne => nil,
                                    :master => nil).order("created_at desc").all
      oauth = nil
      oauths.each do |oa|
        if oa.customer == cust
          if oauth.nil?
            oauth = oa
          else
            # Be proactive resilience here and get rid of this one. We should not have multiples
            logger.error("sessions#ammend_customer: getting rid of multiple customer authentications.")
            oa.destroy()
          end
        else
          redirect_to edit_customer_registration_path(cust), :alert => "This authentication belongs to different customer."
          return
        end
      end
      if oauth
          # Already added
          redirect_to edit_customer_registration_path(cust), :notice => "This authentication already exists"
      else
        oauth = Authentication.create_with_omniauth(auth)
        cust.authentications << oauth
        cust.save
        # We do not change the current_customer_authentication.
        redirect_to edit_customer_registration_path(cust), :notice => "Authentication Added."
      end
    else
      redirect_to customer_sign_in_path, :notice => "Need to sign in first."
    end
  end


  #
  # Called directly from sessions#create
  #
  def create_muni_admin
    session[:muni_admin_id] = nil
    session[:muni_admin_oauth_id] = nil

    auth  = request.env["omniauth.auth"]

    # We should only have one of these.
    oauths = Authentication.where(:provider => auth["provider"],
                                  :uid => auth["uid"],
                                  :muni_admin_id.ne => nil,
                                  :master_id => @master.id).order("created_at desc").all
    oauth = oauths.first
    oauths.drop(1).each do |oa|
      logger.error "sessions#create_muni_admin: Removing extra authentications"
      oa.destroy()
    end
    session[:master_id] = @master.id
    if oauth
      session[:muni_admin_oauth_id] = oauth.id
      muni_admin = oauth.muni_admin
      if muni_admin != nil
        oauth.last_info = auth["info"]
        oauth.save
        session[:muni_admin_id] = muni_admin.id
        redirect_to master_path(muni_admin.master), :notice => "Signed in!"
      else
        redirect_to new_master_muni_admin_registration_path(@master),
                    :notice => "Could not find you. Please create an account."
      end
    else
      oauth = Authentication.create_with_omniauth(auth)
      oauth.master = @master
      oauth.save
      session[:muni_admin_oauth_id] = oauth.id
      redirect_to new_master_muni_admin_registration_path(@master),
                  :notice => "Need to create an account."
    end
  end

  #
  # This method gets called after the user wants to add an authentication.
  #
  def amend_muni_admin
    # we should have a current muni_admin. And we are going to the new authentication if
    # it is not there already.
    muni_admin = current_muni_admin
    if (muni_admin)
      auth  = request.env["omniauth.auth"]
      oauths = Authentication.where(:provider      => auth["provider"],
                                    :uid           => auth["uid"],
                                    :muni_admin_id.ne => nil,
                                    :master_id     => @master.id).order("created_at desc").all
      oauth = nil
      oauths.each do |oa|
        if oa.muni_admin == muni_admin
          if oauth.nil?
            oauth = oa
          else
            # Be proactive resilience here and get rid of this one. We should not have multiples
            logger.error("sessions#ammend_customer: getting rid of multiple administrator authentications.")
            oa.destroy()
          end
        else
          redirect_to edit_master_muni_admin_registration_path(muni_admin.master, muni_admin),
                      :alert => "This authentication belongs to different administrator."
          return
        end
      end
      if oauth
        # Already added
        redirect_to edit_master_muni_admin_registration_path(muni_admin.master, muni_admin),
                    :notice => "This authentication has already been added."
      else
        oauth = Authentication.create_with_omniauth(auth)
        oauth.master = @master
        muni_admin.authentications << oauth
        muni_admin.save
        redirect_to edit_master_muni_admin_registration_path(muni_admin.master, muni_admin),
                    :notice => "Authentication added."
      end
    else
      redirect_to master_muni_admin_sign_in_path(:master_id => params[:master_id]),
                  :alert => "Need to sign in first."
    end
  end

  def create_mobile_user
    create_user(true)
  end

  def amend_mobile_user
    if current_user
      redirect_to "busme://oauthresponse?access_token=#{current_user.get_access_token}&master=#{@master.slug}"
    else
      redirect_to new_user_mobile_sessions_path(@master)
    end
  end

  #
  # Called directly from sessions#create
  #
  def create_user(mobile = nil)
    session[:user_id] = nil
    session[:user_oauth_id] = nil

    auth = request.env["omniauth.auth"]

    oauths = Authentication.where(:provider  => auth["provider"],
                                  :uid       => auth["uid"],
                                  :user_id.ne => nil,
                                  :master_id => @master.id).order("created_at desc").all
    oauth  = oauths.first
    oauths.drop(1).each do |oa|
      logger.error "sessions#create_user: Removing extra authentications"
      oa.destroy()
    end

    session[:master_id] = @master.id
    if oauth
      user = oauth.user
      if user != nil
        if @master != user.master
          # This is really bad.
          logger.error "sessions#create_user: Authentication has mismatched master for user. Removing."
          oauth.destroy()
          redirect_to params[:failure_path] || root_path, :notice => "Session Expired or Invalid. Please retry to sign in."
          return
        end
        session[:user_oauth_id] = oauth.id
        session[:user_id] = user.id
        oauth.last_info = auth["info"]
        oauth.save
        if mobile
          redirect_to "busme://oauthresponse?access_token=#{current_user.get_access_token}&master=#{@master.slug}"
        else
          redirect_to master_active_path(user.master), :notice => "Signed in!"
        end
      else
        session[:user_oauth_id] = oauth.id
        redirect_to new_master_user_registration_path(@master, :mobile => mobile),
                    :notice => "Could not find you. Please create an account."
      end
    else
      oauth = Authentication.create_with_omniauth(auth)
      oauth.master = @master
      oauth.save
      session[:user_oauth_id] = oauth.id
      redirect_to new_master_user_registration_path( @master, :mobile => mobile),
                  :notice => "Need to create an account."
    end
  end

  #
  # We are adding an authentication.
  #
  def amend_user
    # we should have a current user.
    user = current_user
    if (user)
      auth  = request.env["omniauth.auth"]
      # We should have at most one of these.
      oauths = Authentication.where(:provider  => auth["provider"],
                                    :uid       => auth["uid"],
                                    :user_id.ne => nil,
                                    :master_id => @master.id).order("create_at desc").all
      oauth = nil
      oauths.each do |oa|
        if oa.user == user
          if oauth.nil?
            oauth = oa
          else # masters should all be the same
            # Be proactive resilience here and get rid of this one. We should not have multiples
            logger.error("sessions#ammend_customer: getting rid of multiple administrator authentications.")
            oa.destroy()
          end
        else
          redirect_to edit_master_user_registration_path(user.master, user),
                      :alert => "This authentication belongs to different user."
          return
        end
      end
      if oauth
        if @master != oauth.user.master
          # This is really bad. Attempt a fix.
          logger.error "sessions#amend_user: Authentication has mismatched master for user. Removing."
          oauth.destroy()
        end
        redirect_to edit_master_user_registration_path(user.master, user),
                    :notice => "This authentication has already been added."
      else
        oauth        = Authentication.create_with_omniauth(auth)
        oauth.master = @master
        user.authentications << oauth
        user.save
        redirect_to edit_master_user_registration_path(user.master, user),
                    :notice => "Authentication added."
      end
    else
      redirect_to master_user_sign_in_path(@master),
                  :alert => "Need to sign in first."
    end
  end

  def get_context
    #TODO: Fix parsing of :siteslug in face of api.syracuse.busme.us in routes.rb
    #                          |-------------------^^^^^^^^
    # Ex. http://busme.us/auth/google?master_id=22342342234
    @master_id = params[:master_id] || params[:siteslug]
    @master = Master.find(@master_id) || Master.find_by_slug(@master_id)
    if ! @master
      # Ex. http://syracuse.busme.us/auth/google
      #TODO: Fix parsing of :siteslug in face of api.syracuse.busme.us here
      basehost_regex =base_host.gsub(".", "\\.")
      match = /^([a-zA-Z0-9\-\\.]+)\.#{basehost_regex}$/.match(request.host)
      if match
        slug = match[1]
        @master = Master.where(:slug => slug).first
      end
    end
    if ! @master
      @master = Master.find(session[:master_id])
    end
  end

end