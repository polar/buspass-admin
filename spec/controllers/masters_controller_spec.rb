require 'spec_helper'

describe MasterDeploymentsController do

  describe "create action" do

    before(:each) do
      @slug = "t1"
      @database_base = "#Busme-#{Rails.env}"
      @database_name = @database_base + "-" + @slug
      MongoMapper.database = @database_base
      # Database Cleaner should be taking care of this?
      Deployment.delete_all
      Customer.delete_all
      MongoMapper.database = @database_name
      Deployment.delete_all
      Muni::MuniAdmin.delete_all
      MongoMapper.database = @database_base

      @admin = Customer.new(:email => "polar@test.com", :name => "Test User",
                         :password => "123345678", :password_confirmation => "123345678")
      @admin.save!
      @guest = Guest.new

    end

    it "creates the Deployment and its database and Super User" do
      sign_in :busme_masters, @admin
      post 'create', :deployment => { :name => "T1", :location => "0.0,0.0" }
      response.should be_redirect
      assert MongoMapper.database.name === @database_name
      muni = Deployment.first()
      assert_not_nil muni , "deployment is not saved"
      assert muni.name == "T1", "deployment name is not correct"
      assert muni.slug == "t1", "deployment slug is not correct"
      admin = MuniAdmin.first
      assert_not_nil admin, "admin is not saved"
      assert admin.email == @admin.email, "admin email is not correct"
      assert admin.roles_list.reduce(true) {|v,x| [:super,:operator,:planner].include?(x)}, "admin roles incorrect"

      MongoMapper.database =  @database_base
      amuni = Deployment.find_by_slug @slug
      assert_not_nil amuni, "main db deployment is not saved"
      assert amuni.owner == @admin, "main db deployment owner is not correct"
    end

    it "should deny create non admin" do
      post "create", :deployment => { :name => "T1", :location => "0.0,0.0" }
      # There is no admin user that must be authenticated
      response.should be_redirect
    end
  end

  describe "index edit and update actions" do
    before(:each) do
      @slug = "t1"
      @database_base = "#Busme-#{Rails.env}"
      MongoMapper.database = @database_base
      # Database Cleaner should be taking care of this?
      Deployment.delete_all
      Customer.delete_all

      @muni = Deployment.new(:name => "T1", :location => [0.0,0.0])
      @muni.owner = @admin1
      @admin1 = Customer.new(:email => "test1@test.com", :name => "Test User",
                         :password => "123345678", :password_confirmation => "123345678")
      @admin1.save!
      @admin2 = Customer.new(:email => "test2@test.com", :name => "Test User",
                         :password => "123345678", :password_confirmation => "123345678")
      @admin2.save!

      @muni1 = Deployment.new(:name => "T1", :location => [0.0,0.0])
      @muni1.owner = @admin1
      @muni1.save!

      @muni2 = Deployment.new(:name => "T2", :location => [0.0,0.0])
      @muni2.owner = @admin2
      @muni2.save!

    end

    it "should allow index" do
      get "index"
      response.should be_success
      assert_not_nil assigns[:munis]
      assert assigns[:munis].length == 2
      assert assigns[:munis].include?(@muni1)
      assert assigns[:munis].include?(@muni2)
    end

    it "should allow admin index for read" do
      sign_in :busme_masters, @admin1
      get "index", :purpose => "read"
      response.should be_success
      assert_not_nil assigns[:munis]
      assert assigns[:munis].length == 2, "length is incorrect"
      assert assigns[:munis].include?(@muni1)
      assert assigns[:munis].include?(@muni2)
    end

    it "should allow admin limited index for edit" do
      sign_in :busme_masters, @admin1
      get "index", :purpose => "edit"
      response.should be_success
      assert_not_nil assigns[:munis]
      assert assigns[:munis].length == 1, "length is incorrect"
      assert assigns[:munis].include?(@muni1)
      assert !assigns[:munis].include?(@muni2)
    end

    it "should allow edit" do
      sign_in :busme_masters, @admin1
      get "edit", :id => @muni1
      response.should be_success
    end

    it "wrong admin should deny edit" do
      sign_in :busme_masters, @admin2
      lambda { get "edit", :id => @muni1 }.should raise_error(CanCan::AccessDenied)
    end

    it "should accept user for udpate"   do
      sign_in :busme_masters, @admin1
      put "update", :id => @muni1, :deployment => {:name => "T2", :location => "-76.0,43.3"}
      response.should redirect_to(deployment_path(@muni1))
    end

    it "should deny update wrong admin" do
      sign_in :busme_masters, @admin2
      lambda { get "update", :id => @muni1 }.should raise_error(CanCan::AccessDenied)
    end

  end
end
