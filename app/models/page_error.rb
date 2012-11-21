class PageError
  include MongoMapper::Document
  include MongoMapper::Plugins::ActsAsList

  key :request_url, String
  key :request_params, Array
  key :error, String
  key :backtrace, Array


  belongs_to :master
  belongs_to :customer
  belongs_to :muni_admin
  belongs_to :user

  timestamps!

  acts_as_list

  attr_accessible :request_url, :request_params, :error, :backtrace, :master, :customer, :muni_admin, :user
end