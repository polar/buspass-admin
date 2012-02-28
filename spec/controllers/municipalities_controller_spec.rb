require 'spec_helper'

describe MunicipalitiesController do

  describe "POST 'create'" do

    before(:each) do
      @slug = "t1"
      @database_base = "#Busme-#{Rails.env}"
      @database_name = @database_base + "-" + @slug
      MongoMapper.database = @database_base
      # Database Cleaner should be taking care of this?
      Municipality.delete_all
      Admin.delete_all
      MongoMapper.database = @database_name
      Municipality.delete_all
      Muni::MuniAdmin.delete_all
      MongoMapper.database = @database_base

      @admin = Admin.new(:email => "polar@test.com", :name => "Test User",
                         :password => "123345678", :password_confirmation => "123345678")
      @admin.save!
    end

    it "creates the Municipality and its database and Super User" do
      sign_in :admin, @admin
      post 'create', :municipality => { :name => "T1", :location => "0.0,0.0" }
      response.should be_redirect
      assert MongoMapper.database.name === @database_name
      muni = Municipality.first()
      assert_not_nil muni , "municipality is not saved"
      assert muni.name == "T1", "municipality name is not correct"
      assert muni.slug == "t1", "municipality slug is not correct"
      admin = MuniAdmin.first
      assert_not_nil admin, "admin is not saved"
      assert admin.email == @admin.email, "admin email is not correct"
      assert admin.roles_list.reduce(true) {|v,x| [:super,:operator,:planner].include?(x)}, "admin roles incorrect"

      MongoMapper.database =  @database_base
      amuni = Municipality.find_by_slug @slug
      assert_not_nil amuni, "main db municipality is not saved"
      assert amuni.owner == @admin, "main db municipality owner is not correct"
    end
  end

  describe "edit and update" do
    before(:each) do
      @slug = "t1"
      @database_base = "#Busme-#{Rails.env}"
      MongoMapper.database = @database_base
      # Database Cleaner should be taking care of this?
      Municipality.delete_all
      Admin.delete_all

      @muni = Municipality.new(:name => "T1", :location => [0.0,0.0])
      @muni.owner = @admin1
      @admin1 = Admin.new(:email => "test1@test.com", :name => "Test User",
                         :password => "123345678", :password_confirmation => "123345678")
      @admin1.save!
      @admin2 = Admin.new(:email => "test2@test.com", :name => "Test User",
                         :password => "123345678", :password_confirmation => "123345678")
      @admin2.save!

      @muni1 = Municipality.new(:name => "T1", :location => [0.0,0.0])
      @muni1.owner = @admin1
      @muni1.save!

      @muni2 = Municipality.new(:name => "T2", :location => [0.0,0.0])
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
      sign_in :admin, @admin1
      get "index", :purpose => "read"
      response.should be_success
      assert_not_nil assigns[:munis]
      assert assigns[:munis].length == 2, "length is incorrect"
      assert assigns[:munis].include?(@muni1)
      assert assigns[:munis].include?(@muni2)
    end

    it "should allow admin limited index for edit" do
      sign_in :admin, @admin1
      get "index", :purpose => "edit"
      response.should be_success
      assert_not_nil assigns[:munis]
      assert assigns[:munis].length == 1, "length is incorrect"
      assert assigns[:munis].include?(@muni1)
      assert !assigns[:munis].include?(@muni2)
    end

    it "should allow edit" do
      sign_in :admin, @admin1
      get "edit", :id => @muni1
      response.should be_success
    end

    it "wrong admin should deny edit" do
      sign_in :admin, @admin2
      lambda { get "edit", :id => @muni1 }.should raise_error
    end

    it "should accept user"   do
      sign_in :admin, @admin1
      put "update", :id => @muni1, :municipality => {:name => "T2", :location => "-76.0,43.3"}
      response.should redirect_to(municipality_path(@muni1))
    end

    it "wrong admin should deny update" do
      sign_in :admin, @admin2
      lambda { get "update", :id => @muni1 }.should raise_error
    end
  end
end
