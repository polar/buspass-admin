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
  end

  def update
    load_resource

    if resource.update_without_password(params[resource_name])
      flash[:notice] = "Password Updated."
      redirect_to customers_path
    else
      render :edit
    end
  end
end