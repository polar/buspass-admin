class Masters::Mydevise::SessionsController < Devise::SessionsController
  #noinspection RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable

  def auth_options
    if request_format == :json
      recall = "#{controller_path}#failure"
    else
      recall = "#{controller_path}#new"
    end
    { :scope => resource_name, :recall => recall, :master_id => params[:master_id]  }
  end

  def failure
    render :inline => "Email/Password incorrect", :status => 403
  end

  # POST /resource/sign_in
  def create
    resource = warden.authenticate!(auth_options)
    set_flash_message(:notice, :signed_in) if is_navigational_format?
    sign_in(resource_name, resource)
    respond_with resource, :location => after_sign_in_path_for(resource)
  end

  def after_sign_in_path_for(resource)
    setup_municipality
    # Resource should be a Admin
    if @master.nil?
      raise "No Municipality Specified"
    end
    #plan_home_path(:master_id => @master)
    ret= master_municipalities_path(:master_id => @master)
    ret
  end

  def after_sign_out_path_for(resource)
    setup_municipality
    # Resource should be a Admin
    if @master.nil?
      raise "No Municipality Specified"
    end
    master_municipalities_path(:master_id => @master)
  end
end