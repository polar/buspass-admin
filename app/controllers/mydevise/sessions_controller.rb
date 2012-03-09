class Mydevise::SessionsController < Devise::SessionsController

  def new
    super
  end

  def after_sign_in_path_for(resource)
    # Resource should be a Admin
    masters_path
  end

  def after_sign_out_path_for(resource)
    # Resource should be a Admin
    masters_path
  end
end