class Masters::ActiveController < ApplicationController

  def show
    get_context

    if @activement
      options = {:master_id => @master.id, :deployment_id => @deployment.id}
      @job = SimulateJob.first(:activement_id => @activement.id)
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
      @updateUrl = partial_status_master_active_path(@master, :format => :json)
      @loginUrl = api_activement_path(@activement, :format => :json)
    else
      @updateUrl = partial_status_master_active_path(@master, :format => :json)
      flash[:error] = "Busme #{@master.name} is not active."
    end
  end

  def admin
    get_context

    if @activement
      options = { :master_id => @master.id, :deployment_id => @deployment.id }
      @job    = SimulateJob.first(:activement_id => @activement.id)
      #authorize!(:deploy, @deployment)
      @date   = Time.now
      @time   = @date
      if params[:date]
        @date = Time.parse(params[:date])
      end
      if params[:time]
        @time = Time.parse(params[:time])
      end
      @mult   = @job && @job.clock_mult || 1
      @duration = @job && @job.duration || 30
      @processing_status_label = "Run"
      @updateUrl = partial_status_master_active_path(@master, :format => :json)
      @loginUrl = api_activement_path(@activement, :format => :json)
    else
      flash[:error] = "There is no deployment for #{@master.name} that is active."
      redirect_to master_path(@master)
    end
  end

  def status
    get_context

    #authorize!(:read, @deployment)

    options = {:master_id => @master.id, :deployment_id => @deployment.id}
    if @activement
      @job = SimulateJob.where(options).first
      if @job.nil?
        flash[:error] = "There is no simulation running for #{@deployment.name}."
      end
    end
  end

  def start
    get_context

    #authorize!(:deploy, @deployment)
    options = {:activement_id => @activement.id}
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
        @status += "Active Run of #{@master.name}'s #{@deployment.name} is still running."
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

    @job.processing_log << "Submitting Active Deployment job #{@job.name} to system."
    djob = Delayed::Job.enqueue(:queue          => @master.slug,
                                :payload_object =>
                                    VehicleJourneySimulateJob.new(@job.id, @find_interval, @time_interval,
                                                                  @clock, @mult, @duration))
    @job.save!
    @status = "Active Run for #{@deployment.name} has been started."
  end

  def stop
    get_context

    #authorize!(:deploy, @deployment)
    options = {:activement_id => @activement.id}
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
  end

  #
  # This action gets called by a javascript updater on the show page.
  #
  def partial_status
    get_context

    #authorize!(:read, @deployment)

    options = {:activement_id => @activement.id}
    @job = SimulateJob.first(options)
    if @job
      @last_log = params[:log].to_i
      @limit    = (params[:limit] || 10000000).to_i # makes take(@limit) work if no limit.

      @logs       = @job.processing_log.drop(@last_log).take(@limit)

      resp = { :logs => @logs, :last_log => @last_log }

      resp[:start] = !@job.is_processing?
      resp[:stop] = !["Stopped"].include?(@job.processing_status)

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

  def deactivate
    get_context
    authenticate_muni_admin!

    if muni_admin_can?(:delete, @activement)
      options = {:activement_id => @activement.id}
      @job = SimulateJob.first(options)
      # We automatically kill any job if we remove the SimulateJob
      @job.destroy if @job
      @activement.destroy
      flash[:notice] = "#{@master.name} Deployment #{@deployment.name} has been deactivated."
    else
      flash[:error] = "You are not allowed to deactivate #{@master.name} Deployment #{@deployment.name}"
    end
    redirect_to master_deployments_path(@master)
  end

  def api
    get_context

    authorize_muni_admin!(:edit, @deployment)
    @api = {
        :majorVersion => 1,
        :minorVersion => 0,
        "getRoutePath" => route_activement_webmap_path(@activement),
        "getRouteJourneyIds" => route_journeys_activement_webmap_path(@activement),
        "getRouteDefinition" => routedef_activement_webmap_path(@activement),
        "getJourneyLocation" => curloc_activement_webmap_path(@activement)
    }

    respond_to do |format|
      format.json { render :json => @api }
    end
  end

  protected

  def get_context
    @activement = Activement.find(params[:id])
    @activement ||= Activement.find(params[:activement_id])
    @master = @activement.master if @activement
    @master ||= Master.find(params[:master_id])
    @activement ||= Activement.where(:master_id => params[:master_id]).first
    @deployment = @activement.deployment if @activement
  end

end
