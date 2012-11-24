class CustomerRegistrationsController < ApplicationController

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
    @customer = Customer.find(params[:id])

    if @customer != current_customer
      flash[:error] = "Customer mismatch. Please logout and log back in."
      redirect :new
      return
    end
    @authentication = @customer.authentications.find session[:customer_oauth_id]
    if @authentication
      @authentications = @customer.authentications - [@authentication]
      @providers = BuspassAdmin::Application.oauth_providers - @customer.authentications.map {|a| a.provider.to_s }
      @oauth_options = "?tpauth=amend_customer&customer_auth=#{session[:session_id]}&failure_path=#{edit_customer_path}"

      # We put this in the session in case the user adds an authentication.
      session[:tpauth] = :amend_customer
      render
    else
      sign_out(current_customer)
      redirect_to customer_sign_in_path, :notice => "You need to authenticate."
    end

  end

  #
  # This gets called from a redirect from new_registration
  #
  def create
    tpauth = Authentication.find session[:tpauth_id]
    if tpauth
      @customer = Customer.new(params[:customer])
      if Customer.count == 0
        # The first customer has administrative privileges.
        @customer.add_roles([:admin, :super])
      end
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