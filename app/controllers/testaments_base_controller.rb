class TestamentsBaseController < ApplicationController
  before_filter :initialize_testament
  before_filter :dd

  def dd
    authenticate_muni_admin!
  end

  def authorize!(action, obj) {
      raise CanCan::PermissionDenied if muni_admin_cannot?(action, obj)
  end

  def initialize_testament
    @testament = Testament.find(params[:testament_id])
    # TODO: Find by slug
    if @testament == nil
      raise "No Testing Deployment Found"
    end
    @master       = @testament.master
    @municipality = @testament.municipality
  end
end