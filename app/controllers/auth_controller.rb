class AuthController < ApplicationController

  #
  # At least Google redirects here upon a failure. /auth/failure
  # We make the best determination based on the session. But remember
  # the sign in page can be old and out of relative sync, and since the
  # user may be logged in at various levels its not possible to emphatically
  # know where it came from as the callback doesn't include any request information.
  # Basically, (from Google) we only get "/auth/failure?message=invalid_credentials".
  #
  def failure
    @message = params[:message]
    flash[:error] = "Invalid Credentials. Please try again"
    @master = Master.find(session[:master_id])
    if @master
      if current_muni_admin
        redirect_to edit_master_muni_admin_registration_path(@master, current_muni_admin)
      elsif current_user
        redirect_to edit_master_user_registration_path(@master, current_user)
      else
        redirect_to master_active_path(@master)
      end
    else
      if current_customer
        redirect_to edit_customer_registration_path
      else
        redirect_to root_path
      end
    end
  end

end