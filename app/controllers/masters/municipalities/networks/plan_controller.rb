require "delayed_job"

class Masters::Municipalities::Networks::PlanController < Masters::Municipalities::Networks::NetworkBaseController

  def show
    authorize!(:edit, @network)
  end

  def upload
    authorize!(:edit, @network)

    @network_param_name = :plan

    if (@network.processing_lock)
      redirect_to master_municipality_network_plan_path(@network, :master_id => @master.id, :municipality_id => @municipality.id)
    end
  end

  def file
    send_file(@network.file_path,
              :type        => 'application/zip',
              :filename    => File.basename(@network.file_path),
              :disposition => "inline")
  end

  #
  # This action gets called by a javascript updater on the show page.
  #
  def partial_status
    authorize!(:read, @network)

    @last_log = params[:log].to_i
    @last_err = params[:err].to_i
    @limit    = (params[:limit] || 10000000).to_i # makes take(@limit) work if no limit.

    @errors = @network.processing_errors.drop(@last_err).take(@limit)
    @logs   = @network.processing_log.drop(@last_log).take(@limit)

    resp                  = { :errors => @errors, :logs => @logs }
    resp[:services_count] = @network.services.count
    resp[:routes_count]   = @network.routes.count
    resp[:vj_count]       = @network.vehicle_journey_count

    if (@network.processing_completed_at)
      resp[:completed_at] = @network.processing_completed_at.strftime("%m-%d-%Y %H:%M %Z")
    end
    if (@network.processing_started_at)
      resp[:started_at] = @network.processing_started_at.strftime("%m-%d-%Y %H:%M %Z")
    end
    if (@network.file_path)
      resp[:process_file] = file_master_municipality_network_plan_path(@network, :master_id => @master.id, :municipality_id => @municipality.id)
    end
    if (@network.processing_progress)
      resp[:progress] = @network.processing_progress
    end

    respond_to do |format|
      format.json { render :json => resp.to_json }
    end
  end

  def update
    authorize!(:edit, @network)

    if (@network.processing_lock)
      raise "there a job processing."
    end

    if @network.upload_file && @network.upload_file.url && File.exists?(@network.upload_file.url)
      File.rm(@network_file.url)
      @network.upload_file = nil
    end

    @network.update_attributes!(params[:plan])
    @network.upload_file = params[:plan][:upload_file]

    # Save automatically reads the uploaded file and stores it
    @network.save!

    @network.file_path = nil;

    if @network.upload_file && @network.upload_file.url
      # TODO: We should *move* this file somewhere.
      @network.file_path = File.expand_path(File.join(Rails.root, File.join("public", @network.upload_file.url)))
    end

    if @network.file_path && File.exists?(@network.file_path)

      @network.delete_routes()

      @network.processing_lock         = current_muni_admin
      @network.processing_log          = []
      @network.processing_errors       = []
      @network.processing_completed_at = nil
      @network.processing_progress     = 0.0

      @network.save!

      Delayed::Job.enqueue(:payload_object => CompileServiceTableJob.new(@network.id))

      flash[:notice] = "Your job is currently scheduled for processing."
      redirect_to master_municipality_network_plan_path(@network, :master_id => @master.id, :municipality_id => @municipality.id)
    else
      flash[:error] = "Your file was unspecified or not uploaded. Please retry with new file name."
      @network_param_name = :plan
      render :upload
    end
  end

end