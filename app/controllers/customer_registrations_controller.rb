class CustomerRegistrationsController < ApplicationController

  layout "main-layout"

  def new
    @authentication = Authentication.find session[:tpauth_id]
    if @authentication
      cust = Customer.find_by_authentication_id(@authentication.id)
      if cust
        redirect_to edit_customer_registration_path(cust), :notice => "edit"
      else
        @customer = Customer.new()
        @customer.name = @authentication.name
        @customer.email = @authentication.last_info["email"]
        # render form that posts to create_registration
      end
    else
      redirect_to customer_sign_in_path, :notice => "You need to authenticate first."
    end
  end

  def edit
    authenticate_customer!

    @customer = current_customer
    @authentication = @customer.authentications.find session[:tpauth_id]
    @authentications = @customer.authentications - [@authentication]
    @providers = BuspassAdmin::Application.oauth_providers - @customer.authentications.map {|a| a.provider.to_s }

    # We put this in the session in case the user adds an authentication.
    session[:tpauth] = :amend_customer
  end

  #
  # This gets called from a redirect from new_registration
  #
  def create
    tpauth = Authentication.find session[:tpauth_id]
    if tpauth
      @customer = Customer.new(params[:customer])
      @customer.authentications << tpauth
      @customer.save
      session[:customer_id] = @customer.id
      redirect_to edit_customer_registration_path(@customer), :notice => "Signed In!"
    else
      redirect_to customer_sign_in_path, "You need to authenticate first."
    end
  end

  #
  # This gets called from a redirect from edit_registration
  def update
    authenticate_customer!
    # We put this in the session in case the user adds an authentication.
    session[:tpauth] = nil
    tpauth = Authentication.find session[:tpauth_id]
    if tpauth
      @customer = current_customer
      @customer.update_attributes(params[:customer])
      @customer.authentications << tpauth
      @customer.save
      redirect_to edit_customer_registration_path(@customer), :notice => "Account Updated!"
    else
      redirect_to customer_sign_in_path, "You need to authenticate first."
    end
  end

end