class Masters::Municipalities::MunicipalityBaseController < Masters::MasterBaseController

  append_before_filter :set_municipality

  layout "masters/municipalities/application"

  def set_municipality
    @municipality  = Municipality.find(params[:municipality_id])
    if @municipality.nil?
      raise "Municipality Not Found"
    end
    if @municipality.master != @master
      raise "Wrong Deployment for Municipality Master"
    end
  end
end