##
# This class exists merely for live validations
#
require "chronic"

class ServiceCSVFile
  include ActiveModel
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks
  include ActiveModel::Conversion
  include ActiveModel::AttributeMethods
  include ActiveModel::MassAssignmentSecurity

  attr_accessor :name, :code, :sort
  attr_accessor :start_date, :end_date, :direction, :kml

  attr_accessible :name, :code, :sort, :start_date, :end_date, :direction, :kml

  # These are set here for ClientSide Live Validations. We don't save anything.
  validates_numericality_of :sort, :only_integer => true, :allow_nil => true
  validates_presence_of :direction
  validates_presence_of :name
  validates_presence_of :code
  # Date format is validated with ChronicDateValidator in lib.
  validates_date_of :start_date
  validates_date_of :end_date

  def parse_dates
    self.start_date = Chronic.parse(start_date)
    self.end_date = Chronic.parse(end_date)
  end

  # We need this for ActiveMode::Conversion
  def persisted?
    false
  end

  def initialize(params = {})
    assign_attributes(params)
    parse_dates
  end

 def assign_attributes(values, options = {})
   sanitize_for_mass_assignment(values, options[:as]).each do |k, v|
     send("#{k}=", v)
   end
 end

  def csv_file_name
    "#{name}_#{direction}_#{start_date.strftime("%Y-%m-%d")}-#{end_date.strftime("%Y-%m-%d")}.csv".gsub(" ", "_");
  end

  def to_csv
    CSV.generate do |csv|
      csv.add_row(["Route Name", code, sort])
      csv.add_row(["Start Date", start_date.strftime("%Y-%m-%d")])
      csv.add_row(["Start Date", end_date.strftime("%Y-%m-%d")])
      csv.add_row(["Direction", direction])
      names = ["Stop Points", "Days", "Display Name"]
      locations = ["Locations","",""]
      xml =  Hpricot(kml)
      stop_points = xml.search("placemark[@id*=sp]")
      for spdoc in stop_points do
        names << spdoc.at("name").inner_html
        locations << spdoc.at("geometry/point").inner_html
      end
      names << "NOTE"
      names << kml
      csv.add_row(names)
      csv.add_row(locations)
    end
  end
end