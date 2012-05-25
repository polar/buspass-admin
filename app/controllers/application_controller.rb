class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :base_database

  layout "application"

  def base_database
      @database            = "#Busme-#{Rails.env}"
      #MongoMapper.database = @database
      # We try to fill all of these out just in case. Pretty wastefull at this point
      # but can prune according to controller name laster.
      @master = Master.find(params[:master_id]) if params[:master_id]
      @municipality = Municipality.find(params[:municipality_id]) if params[:municipality_id]
    @deployment = Deployment.find(params[:deployment_id]) if params[:deployment_id]
  end
end