class Muni::Plan::ApplicationController < ActionController::Base
    protect_from_forgery
    before_filter :base_database

    # This is the Plan Controller, it must have an authenticated administrator.
    before_filter :authenticate_muni_admin!

    layout "muni/application"

    def base_database
        @slug = params[:muni]
        # We should be checking the main database here for a
        # valid municipality or else these calls could be creating lots
        # of empty databases
        if @slug.blank?
            raise "Municipality Not Specified"
        end
        @database            = "#Busme-#{Rails.env}-#{@slug}"
        MongoMapper.database = @database
        @muni                = Municipality.first
        if @muni.nil?
            raise "Municipality Not Found"
        end
        if @muni.slug != @slug
            raise "Municipality Routing Mismatch"
        end
    end

    def authorize!(action, obj)
      p self.methods
      p current_user_ability(:muni_admin)
      # Looks like muni_admin_can?  is not generated.
      raise CanCan::AccessDenied if current_user_ability(:muni_admin).cannot?(action, obj)
    end

end