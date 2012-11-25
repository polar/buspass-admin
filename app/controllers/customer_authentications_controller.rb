class CustomerAuthenticationsController < ApplicationController
  def index
    @authentications = current_customer.authentications if current_customer
  end

  def destroy
    @authentication = current_customer.authentications.find(params[:id])
    if @authentication
      @authentication.destroy
      flash[:notice] = "Successfully destroyed authentication."
      redirect_to edit_customer_registration_path(current_customer)
    else
      redirect_to customer_sign_in_path
    end
  end

end