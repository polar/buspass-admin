class Mydevise::SessionsController < Devise::SessionsController

  def after_sign_in_path_for(resource)
    setup_municipality
    # Resource should be a Admin
    masters_path
  end

  def after_sign_out_path_for(resource)
    setup_municipality
    # Resource should be a Admin
    masters_path
  end

end