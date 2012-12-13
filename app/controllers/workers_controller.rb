class WorkersController < ApplicationController

  # TODO : Access Control.

  def index
    authenticate_customer!
    @masters = {}
    Master.order("name asc").each do |master|
        @masters[master] = {
        }
    end
  end

  def show
    authenticate_customer!
    @master = Master.find(params[:id])
    @counts = {
        :workers => @master.worker_count,
        :jobs    => @master.delayed_job_count,
        :simulate => @master.simulate_jobs.select{|x| x.delayed_job}.count,
        :compile => @master.service_table_jobs.select{|x| x.delayed_job}.count
    }
    respond_to do |format|
      format.html # show.html.erb
      format.js # show.js
    end

  end

  def start
    authenticate_customer!
    job = WorkerDaemonJob.new(params[:id] || params[:master_id], "start")
    Delayed::Job.enqueue job, :queue => :daemon
  end

  def stop
    authenticate_customer!
    job = WorkerDaemonJob.new(params[:id] || params[:master_id], "stop")
    Delayed::Job.enqueue job, :queue => :daemon
  end


  def start_direct
    authenticate_customer!
    @master = Master.find(params[:id])
    if @master
      @master.delayed_job_start_workers
      flash[:notice] = "Starting Delayed::Job workers in #{@master.name}."
    end
    respond_to do |format|
      format.html { redirect_to workers_path }
      format.js # start.js
    end

  end

  def stop_direct
    authenticate_customer!
    @master = Master.find(params[:id])
    if @master
      @master.delayed_job_stop_workers
      flash[:notice] = "Stopping Delayed::Job workers in #{@master.name}."
    end
    respond_to do |format|
      format.html { redirect_to workers_path }
      format.js
    end
  end

  def up_limit
    authenticate_customer!
    @master = Master.find(params[:id])
    if @master
      @master.max_workers += 1
      @master.save
    end
    respond_to do |format|
      format.html { redirect_to workers_path }
      format.js
    end
  end

  def down_limit
    authenticate_customer!
    @master = Master.find(params[:id])
    if @master
      @master.max_workers -= 1
      @master.save
    end
    respond_to do |format|
      format.html { redirect_to workers_path }
      format.js
    end
  end

  def remove_jobs
    authenticate_customer!
    @master = Master.find(params[:id])
    if @master
      @master.delayed_jobs.each {|job| job.destroy }
      flash[:notice] = "Removed Delayed::Jobs in #{@master.name}"
    end
    respond_to do |format|
      format.html { redirect_to workers_path }
      format.js
    end
  end
end