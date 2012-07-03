class Mydevise::RegistrationsController < Devise::RegistrationsController
  def after_sign_up_path_for(resource)
      # Resource should be a Admin
    my_index_websites_path
  end

  #noinspection RubyInstanceMethodNamingConvention
  def after_inactive_sign_up_path_for(resource)
      # Resource should be a Admin
    my_index_websites_path
  end

  def after_update_path_for(resource)
      # Resource should be a Admin
    my_index_websites_path
  end
end
