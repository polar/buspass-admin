class Deployments::RunController < DeploymentsBaseController

  def map
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
    render :layout => "webmap"
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
    options = {:deployment_id => @deployment.id, :master_id => @master.id, :municipality_id => @municipality.id}
    # Start the "run"
    # Date and time is now
    # mult is 1, which is time multiplier
    # empty the status.
    # duration of -1 means run forever
    @date = Time.now
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
      end
    else
      @job = SimulateJob.new(options)
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
    options = {:deployment_id => @deployment.id, :master_id => @master.id, :municipality_id => @municipality.id}
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

    options = {:deployment_id => @deployment.id, :master_id => @master.id, :municipality_id => @municipality.id}
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
        resp[:sim_time] = @job.sim_time.strftime("%Y-%m-%d %H:%M:%S %Z")
      end
      if (@job.processing_completed_at)
        resp[:completed_at] = @job.processing_completed_at.strftime("%Y-%m-%d %H:%M:%S %Z")
      end
      if (@job.processing_started_at)
        resp[:started_at] = @job.processing_started_at.strftime("%Y-%m-%d %H:%M:%S %Z")
      end
    end

    respond_to do |format|
      format.json { render :json => resp.to_json }
    end
  end

  def api
    authorize!(:read, @municipality)
    @api = {
        :majorVersion => 1,
        :minorVersion => 0,
        "getRoutePath" => route_master_municipality_simulate_webmap_path(@municipality, :master_id => @master.id),
        "getRouteJourneyIds" => route_journeys_master_municipality_simulate_webmap_path(@municipality, :master_id => @master.id),
        "getRouteDefinition" => routedef_master_municipality_simulate_webmap_path(@municipality, :master_id => @master.id),
        "getJourneyLocation" => curloc_master_municipality_simulate_webmap_path(@municipality, :master_id => @master.id)
    }

    respond_to do |format|
      format.json { render :json => @api }
    end
  end

end