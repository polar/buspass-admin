class Masters::Tools::StopPointsFinderController < Masters::MasterBaseController
  layout "masters/map-layout"

  def show
    get_master_context
    authenticate_muni_admin!

    @csv_file = ServiceCSVFile.new();

  end

  ##
  # We always send data back, because the browser will go directly
  # into FileDownload without reloading the page, killing the user's
  # work. If we return a bad file, Excel will notice it.
  #
  def download
    get_master_context
    authenticate_muni_admin!

    @csv_file = ServiceCSVFile.new(params[:service_csv_file])

    send_data @csv_file.to_csv,
              :type => "text/csv; charset=iso-8859-1;header=>present",
              :disposition => "attachment; filename=#{@csv_file.csv_file_name}"
  end

end