class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :base_database

  layout "application"

  def base_database
      @database            = "#Busme-#{Rails.env}"
      MongoMapper.database = @database
  end
end