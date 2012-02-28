class IntegratedDeviseController < ApplicationController
    protect_from_forgery
    before_filter :base_database

    layout :my_layout_function

    #
    # The value is set by the base_database method
    #
    def my_layout_function
      return @mylayout
    end

    ##
    # This call has to work for both the generic top level
    # and for each municipality "site".
    #
    def base_database
        @slug = params[:muni]
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
            # /:muni/muni_admins
            # We are trying for a particular municipality.
            # We need the specific.
            @database            = "#Busme-#{Rails.env}-#{@slug}"
            MongoMapper.database = @database
            @muni                = Municipality.first
            if @muni.nil?
                raise "Municipality Not Found"
            end
            if @muni.slug != @slug
                raise "Municipality Routing Mismatch"
            end
            @mylayout = "muni/application"
        end
        puts "IntegratedDeviseController using #{@database}"
    end
end