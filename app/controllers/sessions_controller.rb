class SessionsController < ApplicationController
  layout "main-layout"

  #
  # This gets called from /auth/:provider/callback
  #
  def create
    # This session variable is set by new_[customer, muni_admin, user, admin]
    case session[:tpauth]
      when :customer
        create_customer()
      when :muni_admin
        create_muni_admin()
      when :amend_customer
        amend_customer()
      when :amend_muni_admin
        amend_muni_admin()
      else
        redirect_to root_url, :notice => "Internal Problem. Could not get tpauth."

    end
    session[:tpauth] = nil
  end

  #
  # Set up a new Customer Session
  #
  def new_customer
    # We are going to auth a muni_admin. We indicate that in the session
    if current_customer
      redirect_to edit_customer_registration_path(current_customer), :notice => "You are already signed in."
    end
    @providers = BuspassAdmin::Application.oauth_providers
    session[:tpauth] = :customer
    # We will render new_muni_admin and then that will redirect to sessions#create on /auth/;provider/callback
  end

  def destroy_customer
    session[:customer_id] = nil
    session[:tpauth_id] = nil
    redirect_to root_path, :notice => "Signed out!"
  end

  #
  # Set up a new Customer Session
  #
  def new_muni_admin
    # We are going to auth a muni_admin. We indicate that in the session
    if current_muni_admin
      redirect_to edit_master_muni_admin_registration_path(current_muni_admin.master, current_muni_admin), :notice => "You are already signed in."
    else
      @providers = BuspassAdmin::Application.oauth_providers
      session[:tpauth] = :muni_admin
      session[:master_id] = params[:master_id]
      # We will render new_muni_admin and then that will redirect to sessions#create on /auth/;provider/callback
      @master = Master.find(params[:master_id])
      render :layout => "masters/normal-layout"
    end

  end

  def destroy_muni_admin
    master = current_muni_admin.master
    session[:muni_admin_id] = nil
    session[:tpauth_id] = nil
    redirect_to master_path(master), :notice => "Signed out!"
  end

  private

  #
  # Called directly from sessions#create
  #
  def create_customer
    auth  = request.env["omniauth.auth"]
    oauth = Authentication.find_by_provider_and_uid_and_master_id(auth["provider"], auth["uid"], nil)
    if oauth
      cust = oauth.customer
      session[:tpauth_id] = oauth.id
      if cust != nil
        session[:customer_id] = cust.id
        oauth.last_info = auth["info"]
        oauth.save
        redirect_to my_index_websites_path, :notice => "Signed in!"
      else
        redirect_to new_customer_registration_path, :notice => "Could not find you. Please create an account."
      end
    else
      session[:tpauth_id] = Authentication.create_with_omniauth(auth).id
      redirect_to new_customer_registration_path, :notice => "Need to create an account."
    end
  end

  #
  # This method gets called after the user wants to add an authentication.
  #
  def amend_customer
    session[:tpauth] = nil
    # we should have a current customer.
    cust = current_customer
    if (cust)
      auth  = request.env["omniauth.auth"]
      oauth = Authentication.find_by_provider_and_uid(auth["provider"], auth["uid"])
      if oauth
        if oauth.customer.nil?
          oauth.customer = cust
          oauth.save
          redirect_to edit_customer_registration_path(cust), :notice => "This authentication already exists"
        elsif cust == oauth.customer
          # Already added
          redirect_to edit_customer_registration_path(cust), :notice => "This authentication already exists"
        else
          session[:customer_id] = nil
          session[:tpauth_id] = nil
          redirect_to customer_sign_in_path, :notice => "Authentication belongs to another customer!"
        end
      else
        oauth = Authentication.create_with_omniauth(auth)
        cust.authentications << oauth
        cust.save
        redirect_to edit_customer_registration_path(cust), :notice => "Authentication failed."
      end
    else
      redirect_to customer_sign_in_path, :notice => "Need to sign in first."
    end
  end


  #
  # Called directly from sessions#create
  #
  def create_muni_admin
    auth  = request.env["omniauth.auth"]

    oauth = Authentication.find_by_provider_and_uid_and_master_id(auth["provider"], auth["uid"], session[:master_id])
    if oauth
      muni_admin = oauth.muni_admin
      session[:tpauth_id] = oauth.id
      if muni_admin != nil
        session[:muni_admin_id] = muni_admin.id
        oauth.last_info = auth["info"]
        oauth.save
        redirect_to master_path(muni_admin.master), :notice => "Signed in!"
      else
        redirect_to new_master_muni_admin_registration_path(:master_id => session[:master_id]),
                    :notice => "Could not find you. Please create an account."
      end
    else
      session[:tpauth_id] = Authentication.create_with_omniauth(auth).id
      redirect_to new_master_muni_admin_registration_path(:master_id => session[:master_id]),
                  :notice => "Need to create an account."
    end
  end

  #
  # This method gets called after the user wants to add an authentication.
  #
  def amend_muni_admin
    session[:tpauth] = nil
    # we should have a current muni_admin.
    muni_admin = current_muni_admin
    if (muni_admin)
      auth  = request.env["omniauth.auth"]
      oauth = Authentication.find_by_provider_and_uid(auth["provider"], auth["uid"])
      if oauth
        if oauth.muni_admin.nil?
          oauth.muni_admin = muni_admin
          oauth.save
          redirect_to edit_master_muni_admin_registration_path(muni_admin.master, muni_admin),
                      :notice => "This authentication has been accepted"
        elsif muni_admin == oauth.muni_admin
          # Already added
          redirect_to edit_master_muni_admin_registration_path(muni_admin.master, muni_admin),
                      :notice => "This authentication has been accepted"
        else
          session[:muni_admin_id] = nil
          session[:tpauth_id] = nil
          redirect_to master_muni_admin_sign_in_path(muni_admin),
                      :notice => "Authentication belongs to another Admin!"
        end
      else
        oauth = Authentication.create_with_omniauth(auth)
        muni_admin.authentications << oauth
        muni_admin.save
        redirect_to edit_master_muni_admin_registration_path(muni_admin.master, muni_admin),
                    :notice => "Authentication failed."
      end
    else
      redirect_to master_muni_admin_sign_in_path(:master_id => params[:master_id]),
                  :notice => "Need to sign in first."
    end
  end

end