class Masters::TestamentController < Masters::MasterBaseController

  def show
    @testament = Testament.where(:master_id => @master.id).first
    @loginUrl = api_deployment_path(@testament) if @testament
  end
end
