class Masters::Deployments::DeploymentBaseController < Masters::MasterBaseController

  append_before_filter :set_deployment

  def set_deployment
    get_master_context
    @deployment  = Deployment.find(params[:deployment_id])
    if @deployment.nil?
      raise "Deployment Not Found"
    end
    if @deployment.master != @master
      raise "Wrong Deployment for Deployment Master"
    end
  end
end