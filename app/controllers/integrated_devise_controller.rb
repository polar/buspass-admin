class IntegratedDeviseController < ApplicationController
    protect_from_forgery

    before_filter :setup_municipality

    layout :my_layout_function

    #
    # The value is set by the base_database method
    #
    def my_layout_function
      @mylayout = "application"
      if @master
        @mylayout = "masters/application"
      end

      return @mylayout
    end

    ##
    # This call has to work for both the generic top level
    # and for each municipality "site".
    # Note: This needs to be explicitly called for anything that isn't
    # a routed action, such as after_sign_in_path_for.
    #
    def setup_municipality
      puts("IntegratedDeviseController eatme2")
      logger.debug "trying to initialize for master and municipality"
      @master = Master.find(params[:master_id]) if params[:master_id]
      @municipality = Municipality.find(params[:municipality_id]) if params[:municipality_id]
    end
=begin
        @slug = params[:masters]
        # We should be checking the main database here for a
        # valid municipality or else these calls could be creating lots
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
            # We are trying for a particular municipality.
            # We need the specific.
            @database            = "#Busme-#{Rails.env}-#{@slug}"
            MongoMapper.database = @database
            @masters                = Municipality.first
            if @masters.nil?
                raise "Municipality Not Found"
            end
            if @masters.slug != @slug
                raise "Municipality Routing Mismatch"
            end
            @mylayout = "masters/application"
        end
        puts "IntegratedDeviseController using #{@database}"
    end
=end
end