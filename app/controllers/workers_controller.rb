class WorkersController < ApplicationController

  def index
    @masters = {}
    Master.order("name asc").each do |master|
        @masters[master] = {
        }
    end
  end

  def show
    @master = Master.find(params[:id])
    @counts = {
        :workers => @master.delayed_job_worker_count,
        :jobs    => @master.delayed_job_count,
        :simulate => @master.simulate_jobs.count,
        :compile => @master.service_table_jobs.count
    }
    respond_to do |format|
      format.html # show.html.erb
      format.js # show.js
    end

  end

  def start
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

  def stop
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