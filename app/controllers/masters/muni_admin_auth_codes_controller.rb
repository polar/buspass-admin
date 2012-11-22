class Masters::MuniAdminAuthCodesController < Masters::MasterBaseController

  def index
    get_master_context
    authenticate_muni_admin!

    authorize_muni_admin!(:read, MuniAdminAuthCode)

    @planners  = []
    @operators = []
    @planner_operators = []
    @master.muni_admin_auth_codes.each do |ac|
      if ac.planner && ac.operator
        @planner_operators << ac.code.to_s
      elsif ac.planner
        @planners << ac.code.to_s
      elsif ac.operator
        @operators << ac.code.to_s
      end
    end
  end

end