class Apis::Discovery1 < Apis::Base

  ALLOWABLE_CALLS = ["get", "discover"]

  def version
    "d1"
  end

  def initialize(api_url_for)
    @api_url_for = api_url_for
  end

  def allowable_calls
    ALLOWABLE_CALLS
  end

  def get(controller)
    text = "<API "
    text += "version='#{version}' "
    text += "discover='#{@api_url_for.call(version, "discover")}' "
    text += "/>"
    controller.render :xml => text, :status => 200
  end

  def discover(controller)
    params = controller.params
    lat = (params[:lat] ||  "43").to_f
    lon = (params[:lon] ||  "-76").to_f
    radius = params[:radius] = 50 # kilometers
    text = "<masters>\n"
    if params[:type] == "T"
      Master.by_location(lon,lat).where(:testament_id.ne => nil).each do |master|
        if master.testament
          text += "<master "
          text += "name='#{master.name}' "
          text += "lon='#{master.longitude}' "
          text += "lat='#{master.latitude}' "
          text += "api='#{@api_url_for.call(master, "t1", "get")}' "
          text += "/>\n"
        end

      end
    else
      masters = Master.by_location(lon, lat).all
      masters = Master.all if masters.empty?
      masters.each do |master|
        if master.activement
          text += "<master "
          text += "name='#{master.name}' "
          text += "lon='#{master.longitude}' "
          text += "lat='#{master.latitude}' "
          text += "api='#{@api_url_for.call(master, "1", "get")}' "
          text += "/>\n"
        end
      end
    end
    text += "</masters>"
    controller.render :xml => text, :status => 200
  end
end