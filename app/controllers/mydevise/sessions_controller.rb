class Mydevise::SessionsController < Devise::SessionsController
  layout "empty"

  def after_sign_in_path_for(resource)
    # Resource should be a Customer
    my_index_websites_path
  end

  def after_sign_out_path_for(resource)
    # Resource should be a Customer
    my_index_websites_path
  end

end