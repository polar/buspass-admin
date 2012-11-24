class Masters::MasterBaseController < ApplicationController

  rescue_from Exception, :with => :rescue_master_admin_error_page

    def get_master_context
      @master = Master.find(params[:master_id])
      # TODO: Find out why we nned to reload @master here?
      # CSc
      @master.reload
      @site = @master.admin_site
      if !@master
        raise NotFoundError.new "Cannot find master."
      end
    end

end