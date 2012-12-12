class Masters::WorkersController < Masters::MasterBaseController

  def index
    get_master_context
    authenticate_muni_admin!
    authorize_muni_admin!(:manage, @master)
    @masters = {}
        @masters[@master] = {
        }
  end

  def show
    get_master_context
    authenticate_muni_admin!
    authorize_muni_admin!(:manage, @master)
    @counts = {
        :workers => @master.delayed_job_worker_count,
        :jobs    => @master.delayed_job_count,
        :simulate => @master.simulate_jobs.select { |x| x.delayed_job }.count,
        :compile  => @master.service_table_jobs.select { |x| x.delayed_job }.count
    }
    respond_to do |format|
      format.html # show.html.erb
      format.js # show.js
    end

  end

  def start
    get_master_context
    authenticate_muni_admin!
    authorize_muni_admin!(:manage, @master)
    job = WorkerDaemonJob.new(@master.id, "start")
    Delayed::Job.enqueue job, :queue => :daemon
  end

  def stop
    get_master_context
    authenticate_muni_admin!
    authorize_muni_admin!(:manage, @master)
    job = WorkerDaemonJob.new(@master.id, "stop")
    Delayed::Job.enqueue job, :queue => :daemon
  end

  def start_direct
    get_master_context
    authenticate_muni_admin!
    authorize_muni_admin!(:manage, @master)
    if @master
      @master.delayed_job_start_workers
      flash[:notice] = "Starting Delayed::Job workers."
    end
    respond_to do |format|
      format.html { redirect_to master_workers_path(@master) }
      format.js # start.js
    end

  end

  def stop_direct
    get_master_context
    authenticate_muni_admin!
    authorize_muni_admin!(:manage, @master)
    if @master
      @master.delayed_job_stop_workers
      flash[:notice] = "Stopping Delayed::Job workers."
    end
    respond_to do |format|
      format.html { redirect_to master_workers_path(@master) }
      format.js
    end
  end

  def up_limit
    get_master_context
    authenticate_muni_admin!
    authorize_muni_admin!(:manage, @master)

    # We don't allow Customers to do their own limits yet.
    #if @master
    #  @master.max_workers += 1
    #  @master.save
    #end
    flash[:error] = "Admin cannot alter max workers."
    respond_to do |format|
      format.html { redirect_to master_workers_path(@master) }
      format.js
    end
  end

  def down_limit
    get_master_context
    authenticate_muni_admin!
    authorize_muni_admin!(:manage, @master)

    # We don't allow Customers to do their own limits yet.
    #if @master
    #  @master.max_workers -= 1
    #  @master.save
    #end
    flash[:error] = "Admin cannot alter max workers."
    respond_to do |format|
      format.html { redirect_to master_workers_path(@master) }
      format.js
    end
  end

  def remove_jobs
    get_master_context
    authenticate_muni_admin!
    authorize_muni_admin!(:manage, @master)
    if @master
      @master.delayed_jobs.each {|job| job.destroy }
      flash[:notice] = "Removed Delayed::Jobs"
    end
    respond_to do |format|
      format.html { redirect_to master_workers_path(@master) }
      format.js
    end
  end
end