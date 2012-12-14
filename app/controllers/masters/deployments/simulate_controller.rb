class Masters::Deployments::SimulateController < Masters::Deployments::DeploymentBaseController
  layout "empty"

  def show
    map
  end

  def map
    authenticate_muni_admin!
    authorize_muni_admin!(:edit, @deployment)
    options = {:master_id => @master.id, :deployment_id => @deployment.id, :disposition => "simulate"}
    @job = SimulateJob.first(options)
    @date = Time.now.in_time_zone(@master.time_zone)
    @time = @date
    if params[:date]
      @date = Time.parse(params[:date])
    end
    if params[:time]
      @time = Time.parse(params[:time])
    end
    @mult = @job && @job.clock_mult || 1
    @duration = @job && @job.duration || 30

    @loginUrl = api_master_deployment_simulate_path(@master, @deployment)
    @center = [@master.longitude.to_f, @master.latitude.to_f]
    @updateUrl = partial_status_master_deployment_simulate_path(@master, @deployment)
  end

  def status
    authorize_muni_admin!(:edit, @deployment)
    options = {:master_id => @master.id, :deployment_id => @deployment.id, :disposition => "simulate"}
    @job = SimulateJob.first(options)
    if @job.nil?
      flash[:error] = "There is no simulation running for #{@deployment.name}."
    end
  end

  def start
    authorize_muni_admin!(:edit, @deployment)
    if false && (@deployment.is_active?)
      @status = "You cannot simulate a deployment that is set up as active or in test."
      return
    end

    options = {:master_id => @master.id, :deployment_id => @deployment.id, :disposition => "simulate"}
    @date = Time.now.in_time_zone(@master.time_zone)
    @time = @date
    @status = ""
    if params[:date]
      begin
        @date = Time.parse(params[:date])
      rescue ArgumentError
        @status = "Badly formatted date."
      end
    end
    if params[:time]
      begin
        @time = Time.parse(params[:time])
      rescue ArgumentError
        @status += " Badly formatted time."
      end
    end
    if params[:mult]
      @mult = params[:mult].to_i;
    end
    if params[:duration]
      @duration = params[:duration].to_i
    end

    if !@status.empty?
      return
    end
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
        @status += " Simulation for #{@deployment.name} is still running."
        return
      else
        @job.destroy()
        @job = SimulateJob.new(options)
        # User may have changed the time zone on the Master.
        @job.time_zone = @master.time_zone
      end
    else
      @job = SimulateJob.new(options)
    end
    @job.save!
    if @mult == 1
      @find_interval = 20
      @time_interval = 10
    else
      @find_interval = 20.0 / @mult
      @time_interval = 10.0 / @mult
    end
    @job.processing_log << "Submitting simulation job #{@job.name} to system."
    vjsjob = VehicleJourneySimulateJob.new(@job.id, @find_interval, @time_interval,
                                           @clock, @mult, @duration)
    djob = Delayed::Job.enqueue vjsjob, :queue => @master.slug
    if djob
      Delayed::Job.enqueue WorkerDaemonJob.new(@master.id, "start"), :queue => :daemon
    end
    @job.save!
    @status = "Simulation for #{@deployment.name} has been started."
  end

  def stop
    authorize_muni_admin!(:edit, @deployment)
    options = {:master_id => @master.id, :deployment_id => @deployment.id, :disposition => "simulate"}
    @job = SimulateJob.first(options)
    if @job
      case @job.processing_status
        when "StopRequested"
          @job.delayed_job = nil
          @job.set_processing_status("Stopping")
          @status = "Attempting to abort job"
          @job.save
        when "Stopping"
          @job.destroy
          @status = "Aborting job"
        else
          @job.set_processing_status!("StopRequested")
          @job.save
      end
      @status = "The simulation for #{@deployment.name} will stop shortly."
    else
      @status = "There is no simulation for #{@deployment.name} to stop."
    end
    respond_to do |format|
      format.js { render :text => @status }
      format.html {
        @date = Time.now.in_time_zone(@master.time_zone)
        @time = @date
        if params[:date]
          @date = Time.parse(params[:date])
        end
        if params[:time]
          @time = Time.parse(params[:time])
        end
        @mult = @job && @job.clock_mult || 1
        @duration = @job && @job.duration || 30
        render :map
      }
    end
  end

  #
  # This action gets called by a javascript updater on the show page.
  #
  def partial_status
    authorize_muni_admin!(:edit, @deployment)

    options = {:master_id => @master.id, :deployment_id => @deployment.id, :disposition => "simulate"}
    @job = SimulateJob.first(options)
    if @job
      # Job may have been updated by another process.
      @job.reload
      @last_log = params[:log].to_i
      @limit    = (params[:limit] || 10000000).to_i # makes take(@limit) work if no limit.

      @logs   = @job.processing_log.drop(@last_log).take(@limit)

      resp = { :logs => @logs, :last_log => @last_log }

      resp[:start] = !@job.is_processing?
      resp[:stop] = !@job.is_stopped?

      if (@job.processing_status)
        resp[:status] = @job.processing_status
      end
      if (@job.clock_mult)
        resp[:clock_mult] = @job.clock_mult
      end
      if (@job.sim_time)
        resp[:sim_time] = @job.sim_time.in_time_zone(@master.time_zone).strftime("%Y-%m-%d %H:%M:%S %Z")
      end
      if (@job.processing_completed_at)
        resp[:completed_at] = @job.processing_completed_at.in_time_zone(@master.time_zone).strftime("%Y-%m-%d %H:%M:%S %Z")
      end
      if (@job.processing_started_at)
        resp[:started_at] = @job.processing_started_at.in_time_zone(@master.time_zone).strftime("%Y-%m-%d %H:%M:%S %Z")
      end
    end

    respond_to do |format|
      format.json { render :json => resp.to_json }
    end
  end

  def api
    authorize_muni_admin!(:edit, @deployment)
    @api = {
        :majorVersion => 1,
        :minorVersion => 0,
        "getRoutePath" => route_master_deployment_simulate_webmap_path(@master, @deployment),
        "getRouteJourneyIds" => route_journeys_master_deployment_simulate_webmap_path(@master, @deployment),
        "getRouteDefinition" => routedef_master_deployment_simulate_webmap_path(@master, @deployment),
        "getJourneyLocation" => curloc_master_deployment_simulate_webmap_path(@master, @deployment)
    }

    respond_to do |format|
      format.json { render :json => @api }
    end
  end

end