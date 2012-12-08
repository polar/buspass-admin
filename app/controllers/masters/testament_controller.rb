class Masters::TestamentController < ApplicationController

  def show
    get_context

    if @testament
      options = {:master_id => @master.id, :deployment_id => @deployment.id}
      @job = SimulateJob.first(options)
      #authorize!(:deploy, @deployment)
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
      @center = [@master.longitude.to_f, @master.latitude.to_f]
      @startUrl = start_master_testament_path(@master, :format => :js)
      @stopUrl = stop_master_testament_path(@master, :format => :js)
      @partialStatusUrl = partial_status_master_testament_path(@master, :format => :json)
    else
      flash[:error] = "You have not selected a Deployment for testing."
      redirect_to master_path(@master)
    end
  end

  def status
    get_context
    #authorize!(:read, @deployment)
    options = {:testament_id => @testament.id}
    @job = SimulateJob.first(options)
    if @job.nil?
      flash[:error] = "There is no simulation running for #{@deployment.name}."
    end
  end

  def start
    get_context
    #authorize!(:deploy, @deployment)
    options = {:testament_id => @testament.id}
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
    rescue Exception => boom
      @status = "Cannot parse time"
      return
    end

    @job = SimulateJob.first(options)
    if @job
      if @job.is_processing?
        @status += "Run of #{@master.name}'s #{@deployment.name} is still running."
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

    # We may parameterize these parameters.
    @find_interval = 20
    @time_interval = 10

    @job.processing_log << "Submitting Testing Deployment job #{@job.name} to system."
    djob = Delayed::Job.enqueue(:queue          => @master.slug,
                                :payload_object =>
                                    VehicleJourneySimulateJob.new(@job.id, @find_interval, @time_interval,
                                                                  @clock, @mult, @duration))
    @job.save!
    @status = "Testing Run for #{@deployment.name} has been started."
  end

  def stop
    get_context

    #authorize!(:deploy, @deployment)
    options = {:testament_id => @testament.id}
    @job = SimulateJob.first(options)
    # TODO: Simultaneous solution needed
    if @job
      if @job.processing_status == "Running"
        @job.set_processing_status!("StopRequested")
        @status =  "The run of #{@master.name}'s '#{@deployment.name} will stop shortly."
      else
        @status = "The run of #{@master.name}'s '#{@deployment.name} is stopping."
      end
    else
      @status =  "There is no run for #{@master.name}'s '#{@deployment.name}  to stop."
    end
  end

  #
  # This action gets called by a javascript updater on the show page.
  #
  def partial_status
    get_context
    #authorize!(:read, @deployment)

    options = {:testament_id => @testament.id}
    @job = SimulateJob.first(options)
    if @job
      @last_log = params[:log].to_i
      @limit    = (params[:limit] || 10000000).to_i # makes take(@limit) work if no limit.

      @logs   = @job.processing_log.drop(@last_log).take(@limit)

      resp                  = { :logs => @logs, :last_log => @last_log }

      resp[:start] = true
      resp[:stop] = false

      if (@job.processing_status)
        resp[:status] = @job.processing_status
        if (@job.processing_status != "Stopped")
          resp[:start] = false
          resp[:stop] = true
        end
        if (@job.processing_status == "StopRequested")
          resp[:start] = false
          resp[:stop] = false
        end
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
    else
      resp = {}
      resp[:start] = true
      resp[:stop] = false
    end

    respond_to do |format|
      format.json { render :json => resp.to_json }
    end
  end

  def deactivate
    get_context

    if muni_admin_can?(:delete, @testament)
      options = {:testament_id => @testament.id}
      @job = SimulateJob.first(options)
      # We automatically kill any job if we remove the SimulateJob
      @job.destroy
      @testament.destroy
      flash[:notice] = "#{@master.name} Testament #{@deployment.name} has been deactivated."
    else
      flash[:error] = "You are not allowed to deactivate #{@master.name} Testament #{@deployment.name}"
    end

    redirect_to master_deployments_path(@master)
  end

  def api
    get_context
    authorize_muni_admin!(:edit, @deployment)
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
    @deployment = @testament.deployment if @testament
  end

  def authorize_muni_admin!(action, obj)
    raise CanCan::AccessDenied if muni_admin_cannot?(action, obj)
  end

end
