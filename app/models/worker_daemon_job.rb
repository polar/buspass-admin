class WorkerDaemonJob < Struct.new(:master_id, :op, :master_answer_id)

  # Very Simple, given our Daemon Worker finds Delayed::Jobs in the daemon queue
  # we either start or stop them.

  def perform
    @master = Master.find(master_id)
    # due to the nature of a continuous running delayed job the master
    # needs to be reloaded because we use the IdentityMap on it.
    # The delayed_job_start_workers method pulls a save call. so it restores
    # the previous state.
    @master.reload
    if @master
      case op
        when "start"
          puts "[Worker Daemon] START workers for #{@master.name}"
          @master.delayed_job_start_workers
        when "stop"
          puts "[Worker Daemon] STOP workers for #{@master.name}"
          @master.delayed_job_stop_workers
        else
      end
    end
  end
end