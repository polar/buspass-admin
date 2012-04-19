class Masters::Mydevise::RegistrationsController < Devise::RegistrationsController

  def index

  end
  def after_sign_up_path_for(resource)
      # Resource should be a Admin
      if @master.nil?
        raise "No Municipality Specified"
      end
      #plan_home_path(:master_id => @master)
      ret= master_municipalities_path(:master_id => @master)
      ret
  end

  def after_inactive_sign_up_path_for(resource)
      # Resource should be a Admin
      if @master.nil?
        raise "No Municipality Specified"
      end
      #plan_home_path(:master_id => @master)
      ret= master_municipalities_path(:master_id => @master)
      ret
  end

  def after_update_path_for(resource)
      # Resource should be a Admin
      if @master.nil?
        raise "No Municipality Specified"
      end
      #plan_home_path(:master_id => @master)
      ret= master_municipalities_path(:master_id => @master)
      ret
  end
end