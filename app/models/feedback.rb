class Feedback
  include MongoMapper::Document
  include Paperclip::Glue

  key :subject, String, :default => "No Subject"
  key :message, String
  key :request_url, String
  key :screenshot_file_name, String

  has_attached_file :screenshot

  timestamps!

  belongs_to :customer
  belongs_to :muni_admin
  belongs_to :user

  belongs_to :master

  attr_accessor :screenshot_data
  attr_accessor :include_screenshot

  attr_accessible :subject, :message, :request_url, :screenshot_data, :include_screenshot

  before_validation :decode_screenshot_data, :if => :screenshot_data_provided?

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

  def screenshot_data_provided?
    !self.screenshot_data.blank?
  end

  def decode_screenshot_data
      # If cover_image_data is set, decode it and hand it over to Paperclip
    match = /^data\:([\w\/]*);base64,(.*)/.match(self.screenshot_data)
    content_type = match[1]
    shdata = match[2]
    data = StringIO.new(Base64.decode64(shdata))
    data.class.class_eval { attr_accessor :original_filename, :content_type }
    data.original_filename = "screenshot.png"
    data.content_type = content_type
    self.screenshot = data
  end
end