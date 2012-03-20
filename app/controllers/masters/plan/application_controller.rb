class Muni::Plan::ApplicationController < Muni::ApplicationController::Base

    # This is the Plan Controller, it must have an authenticated administrator.
    before_filter :authenticate_muni_admin!

    layout "masters/application"

    protected

    def base_database
      super
      @municipality  = Municipality.find(params[:municipality_id])
      if @municipality.nil?
        raise "Deployment Not Found"
      end
      if @municipality.master != @master
        raise "Wrong Deployment for Municipality"
      end

       #@slug = params[:masters]
       # # We should be checking the main database here for a
       # # valid municipality or else these calls could be creating lots
       # # of empty databases
       # if @slug.blank?
       #     raise "Municipality Not Specified"
       # end
       # @database            = "#Busme-#{Rails.env}-#{@slug}"
       # MongoMapper.database = @database
       # @masters                = Municipality.first
       # if @masters.nil?
       #     raise "Municipality Not Found"
       # end
       # if @masters.slug != @slug
       #     raise "Municipality Routing Mismatch"
       # end
    end
=begin

    def authorize!(action, obj)
      p current_user_ability(:muni_admin)
      # Looks like muni_admin_can?  is not generated.
      raise CanCan::AccessDenied if current_user_ability(:muni_admin).cannot?(action, obj)
    end
=end

end