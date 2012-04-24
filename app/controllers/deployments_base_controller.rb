class DeploymentsBaseController < ApplicationController
   before_filter :initialize_deployment
   before_filter :authenticate_muni_admin!

  def initialize_deployment
    @deployment = Deployment.find(params[:deployment_id]);
    # TODO: Find by slug
    if @deployment == nil
      raise "No Deployment Found"
    end
    @master = @deployment.master
    @municipality = @deployment.municipality
  end
end