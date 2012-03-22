class Masters::Municipalities::MunicipalityBaseController < Masters::MasterBaseController

  append_before_filter :set_municipality

  def set_municipality
    @municipality  = Municipality.find(params[:municipality_id])
    if @municipality.nil?
      raise "Master Not Found"
    end
    if @municipality.master != @master
      raise "Wrong Deployment for Municipality Master"
    end
  end
end