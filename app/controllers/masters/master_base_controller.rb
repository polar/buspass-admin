class Masters::MasterBaseController < ApplicationController

    layout "empty"

    def get_master_context
      @master = Master.find(params[:master_id])
      # TODO: Find out why we nned to reload @master here?
      # CSc
      @master.reload
      @site = @master.admin_site
    end

end