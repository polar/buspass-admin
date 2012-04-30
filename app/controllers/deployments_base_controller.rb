class DeploymentsBaseController < ApplicationController
  before_filter :initialize_deployment
  before_filter :dd

  def dd
    authenticate_muni_admin!
  end

  def authorize!(action, obj)
      raise CanCan::PermissionDenied if muni_admin_cannot?(action, obj)
  end

  def initialize_deployment
    @deployment = Deployment.find(params[:deployment_id])
    # TODO: Find by slug
    if @deployment == nil
      raise "No Deployment Found"
    end
    @master       = @deployment.master
    @municipality = @deployment.municipality
  end
end