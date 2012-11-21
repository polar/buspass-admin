class Masters::MuniAdminsDevise::RegistrationsController <  Devise::RegistrationsController
  layout "empty"

  def after_sign_in_path_for(resource)
    setup_deployment
    # Resource should be a MuniAdmin
    if @master.nil?
      raise "No Deployment Specified"
    end
    #plan_home_path(:master_id => @master)
    ret= master_deployments_path(@master)
    ret
  end

  def after_sign_up_path_for(resource)
    setup_deployment
    # Resource should be a MuniAdmin
    if @master.nil?
      raise "No Deployment Specified"
    end
    #plan_home_path(:master_id => @master)
    ret= master_deployments_path( @master)
    ret
  end

  def after_inactive_sign_up_path_for(resource)
    setup_deployment
      # Resource should be a MuniAdmin
      if @master.nil?
        raise "No Deployment Specified"
      end
      #plan_home_path(:master_id => @master)
      ret= master_deployments_path(@master)
      ret
  end

  def after_update_path_for(resource)
    setup_deployment
      # Resource should be a MuniAdmin
      if @master.nil?
        raise "No Deployment Specified"
      end
      #plan_home_path(:master_id => @master)
      ret= master_deployments_path(@master)
      ret
  end
end
