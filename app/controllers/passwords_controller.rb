class PasswordsController < ApplicationController
  before_filter :authenticate_customer!
  helper_method :resource, :resource_name

  attr_accessor :resource
  attr_accessor :resource_name


  def load_resource
    self.resource = Customer.find(params[:id])
    self.resource ||= MuniAdmin.find(params[:id])
    self.resource ||= User.find(params[:id])
    self.resource_name = resource.class.name.underscore
  end

  def edit
    load_resource
    respond_to { |format|
      format.html # edit.html.erb
      format.js # edit.js.erb
    }
  end

  def update
    load_resource

    if resource.update_attributes(params[resource_name])
      flash[:notice] = "Password Updated."
      respond_to do |format|
        format.html { redirect_to customers_path }
        format.js # update.js.erb
      end
    else
      flash[:error] = "Password not updated."

      respond_to do |format|
        format.html { render :edit }
        format.js # update.js.erb
      end
    end
  end

  def modal_update
    load_resource

    if resource.update_without_password(params[resource_name])
      flash[:notice] = "Password Updated."
      redirect_to customers_path
    else
      flash[:notice] = "Password not updated."
      render :edit
    end
  end
end