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

  # GET /resource/sign_in
  def new
    resource = build_resource
    clean_up_passwords(resource)
    if request_format == :json
      render :json => {}.merge(csrf_params).merge(master_params)
    else
      respond_with(resource, serialize_options(resource))
    end
  end

  # POST /resource/sign_in
  def create
    # We are using the .json format to log in from the Android.
    #if request_format == :json
    #  env["devise.allow_params_authentication"] = true
    #end
    resource = warden.authenticate!(auth_options)
    if request_format == :json
      sign_in(resource_name, resource)
      cookies["username"] = resource.email
      cookies[Devise.token_authentication_key] = resource.authentication_token
      render :inline => "Signed In.", :status => 200
    else
      set_flash_message(:notice, :signed_in) if is_navigational_format?
      sign_in(resource_name, resource)
      respond_with resource, :location => after_sign_in_path_for(resource)
    end

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

  private

  def csrf_params
    {
        'csrf-param' => request_forgery_protection_token,
        'csrf-token' => form_authenticity_token
    }
  end

  def master_params
    {
        'master-param' => "master_id",
        'master-token' => @master.id
    }
  end
end