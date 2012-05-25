class Masters::MasterBaseController < ApplicationController

    before_filter :set_master

    before_filter :authenticate_muni_admin!
    #def authenticate_muni_admin!
    #  redirect_to(:url => "muni_admins/sign_in", :master_id => @master, :municipality_id => @municipality) if current_muni_admin.nil?
    #end

    def authorize!(action, obj)
      raise CanCan::AccessDenied if muni_admin_cannot?(action, obj)
    end

    layout "masters/normal-layout"

    def set_master
=begin
        @slug = params[:masters]
        # We should be checking the main database here for a
        # valid municipality or else these calls could be creating lots
        # of empty databases
        if @slug.blank?
            raise "Municipality Not Specified"
        end
        @database            = "#Busme-#{Rails.env}-#{@slug}"

        MongoMapper.database = @database

        # We need to set the database name for all because it's been set this way in other operations.
        Master.set_database_name(@database)
        MuniAdmin.set_database_name(@database)
        Municipality.set_database_name(@database)

        Network.set_database_name(@database)
        Service.set_database_name(@database)
        Route.set_database_name(@database)
        VehicleJourney.set_database_name(@database)

=end
      @master  = Master.find(params[:master_id])
      @site = Cms::Site.find_by_id(params[:site_id])
      if @site && @master != @site.master
        @master = @site.master if @site.master
      end
      if @master && @site.nil?
        sites = Cms::Site.where(:master_id => @master.id).all
        if sites.empty?
        else
          @site = sites.first
        end

      end
        if @master.nil?
            raise "Master Not Found"
        end
    end


    ##
    # For sorting Route Codes. Most significant is last 2 digits, then the first.
    #
    def codeOrd(code1, code2)
      code1 = code1.to_i
      base1 = code1 % 100
      code2 = code2.to_i
      base2 = code2 % 100
      if (base1 == base2)
        code1/100 <=> code2/100
      else
        base1 <=> base2
      end
    end

end