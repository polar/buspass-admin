require 'spec_helper'

describe Muni::Plan::HomeController do

    before(:each) do
        @slug = "t1"
        @database_name = "#Busme-#{Rails.env}-#{@slug}"
        MongoMapper.database = @database_name
        # Database Cleaner should be taking care of this?
        Deployment.delete_all
        Muni::MuniAdmin.delete_all

        @tmuni = Deployment.new(:name => "T1", :location => [0.0,0.0])
        @tmuni.save!

        @admin = MuniAdmin.new(:email => "polar@test.com", :name => "Test User",
                               :password => "123345678", :password_confirmation => "123345678")
        @admin.save!
    end

    describe "GET 'Show'" do
        it "should decipher the right database and return the right Deployment" do
            sign_in :muni_admin, @admin
            get 'show', :masters => @slug
            assigns[:database].equal?(@database_name)
            assigns[:slug].equal?(@slug)
            assigns[:masters].equal?(@tmuni)
            response.should be_success
        end
    end
end
