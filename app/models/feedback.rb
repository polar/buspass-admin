class Feedback
  include MongoMapper::Document

  key :message, String

  timestamps!

  belongs_to :customer
  belongs_to :muni_admin
  belongs_to :user

  belongs_to :master

end