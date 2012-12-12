class WorkerDaemonJob < Struct.new(:master_id, :op)

  # Very Simple, given our Daemon Worker finds Delayed::Jobs in the daemon queue
  # we either start or stop them.

  def perform
    @master = Master.find(master_id)
    if @master
      case op
        when "start"
          @master.delayed_job_start_workers
        when "stop"
          @master.delayed_job_stop_workers
        else
      end
    end
  end
end