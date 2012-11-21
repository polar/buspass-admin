class IntegratedDeviseController < ApplicationController
    protect_from_forgery

    before_filter :setup_deployment

    layout :my_layout_function

    #
    # The value is set by the base_database method
    #
    def my_layout_function
      @mylayout = "application"
      if @master
        @mylayout = "masters/normal-layout"
      end

      return @mylayout
    end

    ##
    # This call has to work for both the generic top level
    # and for each deployment "site".
    # Note: This needs to be explicitly called for anything that isn't
    # a routed action, such as after_sign_in_path_for.
    #
    def setup_deployment
      puts("IntegratedDeviseController eatme2")
      logger.debug "trying to initialize for master and deployment"
      @master = Master.find(params[:master_id]) if params[:master_id]
      @deployment = Deployment.find(params[:deployment_id]) if params[:deployment_id]
    end
=begin
        @slug = params[:masters]
        # We should be checking the main database here for a
        # valid deployment or else these calls could be creating lots
        # of empty databases
        if @slug.blank?
            # /admins
            # We assume that we are at the top level.
            # All authenticatable objects are in the main database
            @database = "#Busme-#{Rails.env}"
            MongoMapper.database = @database
            @mylayout = "application"
        else
            # /:masters/muni_admins
            # We are trying for a particular deployment.
            # We need the specific.
            @database            = "#Busme-#{Rails.env}-#{@slug}"
            MongoMapper.database = @database
            @masters                = Deployment.first
            if @masters.nil?
                raise "Deployment Not Found"
            end
            if @masters.slug != @slug
                raise "Deployment Routing Mismatch"
            end
            @mylayout = "masters/application"
        end
        puts "IntegratedDeviseController using #{@database}"
    end
=end
end