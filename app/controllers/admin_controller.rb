class AdminController < ApplicationController
  layout "empty"

  def show
    authenticate_customer!
    authorize_customer!(:manage, Website)
    @site = Cms::Site.find_by_identifier("busme-main")
  end

end
