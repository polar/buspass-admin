class Muni::ApplicationController < ActionController::Base
    protect_from_forgery
    before_filter :base_database

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