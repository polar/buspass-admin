class Masters::Mydevise::RegistrationsController < Devise::RegistrationsController
  def after_sign_up_path_for(resource)
      super
  end

  def after_inactive_sign_up_path_for(resource)
      super
  end

  def after_update_path_for(resource)
      super
  end
end
