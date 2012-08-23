class CustomerAuthenticationsController < ApplicationController
  def index
    @authentications = current_customer.authentications if current_customer
  end

  def create
    auth = request.env["rack.auth"]
    current_customer.authentications.find_or_create_by_provider_and_uid(auth['provider'], auth['uid'])
    flash[:notice] = "Authentication successful."
    redirect_to edit_registration_customer_path
  end

  def destroy
    @authentication = current_customer.authentications.find(params[:id])
    @authentication.destroy
    flash[:notice] = "Successfully destroyed authentication."
    redirect_to edit_registration_customers_path
  end

end