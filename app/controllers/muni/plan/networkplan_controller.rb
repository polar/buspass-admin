require "delayed_job"

class Muni::Plan::NetworkplanController < Muni::Plan::NetworkController

  def show
    authorize!(:edit, @network)
  end

  def upload
    authorize!(:edit, @network)
    @network_param_name = :networkplan
    if (@network.processing_lock)
      redirect_to plan_networkplan_path(:muni => @muni.slug, :network => @network)
    end
  end

  def partial_status
    authorize!(:read, @network)
    @last_log = params[:log].to_i
    @last_err = params[:err].to_i
    @limit    = (params[:limit] || 10000000).to_i # stupid number

    @errors = @network.processing_errors.drop(@last_err).take(@limit)
    @logs   = @network.processing_log.drop(@last_log).take(@limit)
    resp = { :errors => @errors, :logs => @logs }
    resp[:services_count] = @network.services.count
    resp[:routes_count] = @network.routes.count
    resp[:vj_count] = @network.vehicle_journey_count
    if (@network.processing_completed_at)
      resp[:completed_at] = @network.processing_completed_at.strftime("%m-%d-%Y %H:%M %Z")
    end
    if (@network.processing_started_at)
      resp[:started_at] = @network.processing_started_at.strftime("%m-%d-%Y %H:%M %Z")
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
    @network.upload_file = nil
    @network.update_attributes(params[:networkplan])
    @network.save!
    if @network.upload_file && @network.upload_file.url
      # TODO: We should *move* this file somewhere.
      @network.file_path = File.expand_path(File.join(Rails.root, File.join("public", @network.upload_file.url)))

      @network.delete_routes()
      @network.processing_lock         = current_muni_admin
      @network.processing_log          = []
      @network.processing_errors       = []
      @network.processing_completed_at = nil
      @network.save
      # We have to give the @network.id here because this object has to be serialized.
      Delayed::Job.enqueue(:payload_object => CompileServiceTableJob.new(MongoMapper.database.name, @network))
      #dir = Dir.mktmpdir
      ## TODO: Clean up this file path stuff.
      #unzip(File.join(Rails.root,File.join("public",@network.file.url)),dir)
      #ServiceTable.rebuildRoutes(@network, dir)
      flash[:notice] = "Your job is currently being processed."
      redirect_to plan_networkplan_path(:muni => @muni.slug, :network => @network)
    else
      flash[:error] = "Your file was unspecified or not uploaded."
      render :upload
    end
  end

end