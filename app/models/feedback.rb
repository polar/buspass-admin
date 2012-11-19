class Feedback
  include MongoMapper::Document

  key :subject, String, :default => "No Subject"
  key :message, String
  key :request_url, String

  timestamps!

  belongs_to :customer
  belongs_to :muni_admin
  belongs_to :user

  belongs_to :master

  class Guest
    def name
      "Joe Guest"
    end
    def email
      "guest@#{BuspassAdmin::Application.base_host}"
    end
  end
  def sender
    snd = customer || muni_admin || user || Guest.new
  end
end