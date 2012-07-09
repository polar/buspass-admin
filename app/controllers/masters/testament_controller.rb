class Masters::TestamentController < Masters::MasterBaseController
  before_filter :get_context

  def show
    if @testament
      options = {:master_id => @master.id, :municipality_id => @municipality.id}
      @job = SimulateJob.first(options)
      #authorize!(:deploy, @municipality)
      @date = Time.now
      @time = @date
      if params[:date]
        @date = Time.parse(params[:date])
      end
      if params[:time]
        @time = Time.parse(params[:time])
      end
      @mult = @job && @job.clock_mult || 1
      @duration = @job && @job.duration || 30
      @processing_status_label = "Run"
      @updateUrl = partial_status_master_testament_path(@master, :format => :json)
      @loginUrl = api_testament_path(@testament, :format => :json)
    else
      flash[:error] = "You have not selected a Deployment for testing."
      redirect_to master_municipalities_path(@master)
    end
  end

  def status
    #authorize!(:read, @municipality)
    options = {:master_id => @master.id, :municipality_id => @municipality.id}
    @job = SimulateJob.first(options)
    if @job.nil?
      flash[:error] = "There is no simulation running for #{@municipality.name}."
    end
  end

  def start
    #authorize!(:deploy, @municipality)
    options = {:testament_id => @testament.id, :master_id => @master.id, :municipality_id => @municipality.id}
    # Start the "run"
    # Date and time is now
    # mult is 1, which is time multiplier
    # empty the status.
    # duration of -1 means run forever
    @date = Time.now.in_time_zone(@master.time_zone)
    @time = @date

    @mult = 1
    @status = ""
    @duration = -1
    begin
      @clock = Time.parse(@date.strftime("%Y-%m-%d") + " " + @time.strftime("%H:%M %Z"))
      @status = "WTF?"
    rescue Exception => boom
      @status = "Cannot parse time"
      return
    ensure
      @status = "GODMAN"
    end


    @job = SimulateJob.first(options)
    if @job
      if @job.is_processing?
        @status += "Run of #{@master.name}'s #{@municipality.name} is still running."
        return
      else
        @job.reinitialize()
        # User may have changed the time zone on the Master.
        @job.time_zone = @master.time_zone
      end
    else
      @job = SimulateJob.new(options)
      @job.time_zone = @master.time_zone
    end
    @job.save!
    if @mult == 1
      @find_interval = 60
      @time_interval = 10
    else
      @find_interval = 60 / @mult
      @time_interval = 10 / @mult
    end

    # Schedule the job with delayed_job
    job = VehicleJourney.delay.simulate_all(@find_interval, @time_interval, @clock, @mult, @duration, options)
    @job.delayed_job = job
    @job.save!
    @status = "Run of #{@master.name}'s #{@municipality.name} has been started."
  end

  def stop
    #authorize!(:deploy, @municipality)
    options = {:testament_id => @testament.id, :master_id => @master.id, :municipality_id => @municipality.id}
    @job = SimulateJob.first(options)
    # TODO: Simultaneous solution needed
    if @job && @job.processing_status == "Running"
      @job.set_processing_status!("StopRequested")
      render :text => "The run of #{@master.name}'s '#{@municipality.name} will stop shortly."
    else
      render :text => "There is no run for #{@master.name}'s '#{@municipality.name}  to stop."
    end
  end

  #
  # This action gets called by a javascript updater on the show page.
  #
  def partial_status
    #authorize!(:read, @municipality)

    options = {:testament_id => @testament.id, :master_id => @master.id, :municipality_id => @municipality.id}
    @job = SimulateJob.first(options)
    if @job
      @last_log = params[:log].to_i
      @limit    = (params[:limit] || 10000000).to_i # makes take(@limit) work if no limit.

      @logs   = @job.processing_log.drop(@last_log).take(@limit)

      resp                  = { :logs => @logs }

      if (@job.processing_status)
        resp[:status] = @job.processing_status
      end
      if (@job.clock_mult)
        resp[:clock_mult] = @job.clock_mult
      end
      if (@job.sim_time)
        resp[:sim_time] = @job.sim_time.in_time_zone(@job.time_zone).strftime("%Y-%m-%d %H:%M:%S %Z")
      end
      if (@job.processing_completed_at)
        resp[:completed_at] = @job.processing_completed_at.in_time_zone(@job.time_zone).strftime("%Y-%m-%d %H:%M:%S %Z")
      end
      if (@job.processing_started_at)
        resp[:started_at] = @job.processing_started_at.in_time_zone(@job.time_zone).strftime("%Y-%m-%d %H:%M:%S %Z")
      end
    end

    respond_to do |format|
      format.json { render :json => resp.to_json }
    end
  end

  def deactivate
    authorize_muni_admin!(:delete, @testament)

    options = {:testament_id => @testament.id, :master_id => @master.id, :municipality_id => @municipality.id}
    @job = SimulateJob.first(options)
    # We automatically kill any job if we remove the SimulateJob
    @job.destroy
    @testament.destroy
    flash[:notice] = "#{@master.name} Testament #{@municipality.name} has been deactivated."
    redirect_to master_municipalities_path(@master)
  end

  def api
    authorize_muni_admin!(:edit, @municipality)
    @api = {
        :majorVersion => 1,
        :minorVersion => 0,
        "getRoutePath" => route_testament_webmap_path(@testamentd),
        "getRouteJourneyIds" => route_journeys_testament_webmap_path(@testament),
        "getRouteDefinition" => routedef_testament_webmap_path(@testament),
        "getJourneyLocation" => curloc_testament_webmap_path(@testament)
    }

    respond_to do |format|
      format.json { render :json => @api }
    end
  end

  protected

  def get_context
    @testament = Testament.find(params[:id])
    @testament ||= Testament.find(params[:testament_id])
    @master = @testament.master if @testament
    @master ||= Master.find(params[:master_id])
    @testament ||= Testament.where(:master_id => params[:master_id]).first
    @municipality = @testament.municipality if @testament
  end
end
