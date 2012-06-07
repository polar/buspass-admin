class Masters::ActiveController < Masters::MasterBaseController

  def show
    @deployment = Deployment.where(:master_id => @master.id).first
    @loginUrl = api_deployment_path(@deployment) if @deployment
  end
end
