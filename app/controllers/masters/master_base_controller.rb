class Masters::MasterBaseController < ApplicationController

    layout "empty"

    def get_master_context
      @master = Master.find(params[:master_id])
      @site = @master.admin_site
    end

end