class Masters::MuniAdminsDevise::RegistrationsController <  Devise::RegistrationsController

  def after_sign_in_path_for(resource)
    setup_municipality
    # Resource should be a MuniAdmin
    if @master.nil?
      raise "No Municipality Specified"
    end
    #plan_home_path(:master_id => @master)
    ret= master_municipalities_path(@master)
    ret
  end
  def after_sign_up_path_for(resource)
    setup_municipality
    # Resource should be a MuniAdmin
    if @master.nil?
      raise "No Municipality Specified"
    end
    #plan_home_path(:master_id => @master)
    ret= master_municipalities_path( @master)
    ret
  end

  def after_inactive_sign_up_path_for(resource)
    setup_municipality
      # Resource should be a MuniAdmin
      if @master.nil?
        raise "No Municipality Specified"
      end
      #plan_home_path(:master_id => @master)
      ret= master_municipalities_path(@master)
      ret
  end

  def after_update_path_for(resource)
    setup_municipality
      # Resource should be a MuniAdmin
      if @master.nil?
        raise "No Municipality Specified"
      end
      #plan_home_path(:master_id => @master)
      ret= master_municipalities_path(@master)
      ret
  end
end
