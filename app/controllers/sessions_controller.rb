class SessionsController < ApplicationController
  layout "main-layout"

  def create
    case session[:tpauth]
      when :customer
        create_customer()
      else
        redirect_to root_url, :notice => "Could not get tpauth"

    end
    session[:tpauth] = nil
  end

  def new_customer
    # We are going to auth a customer. We indicate that in the session
    session[:tpauth] = :customer
  end

  def create_customer
    auth  = request.env["omniauth.auth"]
    oauth = ThirdPartyAuth.find_by_provider_and_uid(auth["provider"], auth["uid"])
    if oauth
      cust = oauth.customer
      if cust != nil
        session[:customer_id] = cust.id
        session[:tpauth] = nil
        redirect_to root_path, :notice => "Signed in!"
      else
        session[:tpauth_id] = oauth.id
        redirect_to new_registration_customers_path, :notice => "Could not find you."
      end

    else
      session[:tpauth_id] = ThirdPartyAuth.create_with_omniauth(auth).id
      redirect_to new_registration_customers_path, :notice => "Need to create login."
    end
  end

  def destroy_customer
    session[:customer_id] = nil
    redirect_to root_url, :notice => "Signed out!"
  end
end