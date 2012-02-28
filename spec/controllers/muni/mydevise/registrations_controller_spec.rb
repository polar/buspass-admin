require 'spec_helper'

describe Muni::Mydevise::RegistrationsController do

  describe "GET 'after_sign_up_path_for'" do
    it "returns http success" do
      get 'after_sign_up_path_for'
      response.should be_success
    end
  end

  describe "GET 'after_sign_in_path_for'" do
    it "returns http success" do
      get 'after_sign_in_path_for'
      response.should be_success
    end
  end

  describe "GET 'after_inactive_sign_up_path_for'" do
    it "returns http success" do
      get 'after_inactive_sign_up_path_for'
      response.should be_success
    end
  end

  describe "GET 'after_update_path_for'" do
    it "returns http success" do
      get 'after_update_path_for'
      response.should be_success
    end
  end

end
