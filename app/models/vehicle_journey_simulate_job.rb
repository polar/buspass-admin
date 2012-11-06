class VehicleJourneySimulateJob < Struct.new(:simulate_job_id, :find_interval, :time_interval, :clock, :mult, :duration)

  def logger
    Rails.logger
  end

  def say(text, level = Logger::INFO)
    text = "[Simulate] #{text}"
    puts text unless @quiet
    logger.add level, "#{Time.now.strftime('%FT%T%z')}: #{text}" if logger
  end

  def enqueue(djob)
    sjob = SimulateJob.find(simulate_job_id)
    if sjob
        sjob.delayed_job = djob
        sjob.set_processing_status("Enqueued")
        sjob.processing_log << "Job #{sjob.name} has been queued for execution."
        sjob.save
    else
      logger.info("Submitted job has been removed before enqueue.")
    end
  end

  def perform
    begin
      job = SimulateJob.find(simulate_job_id)
      if (job)
        if job.delayed_job
          if job.processing_status == "Enqueued"
            job.processing_log << "Job #{job.name} is about to execute...."
            job.processing_log << "find_interval = #{find_interval}, time_interval = #{time_interval}, time = #{clock}, mult = #{mult}, duration = #{duration}"
            job.save
            VehicleJourney.simulate_all(job.id, find_interval, time_interval, clock, mult, duration)
            job.processing_log << "Job #{job.name} ended normally."
            job.save
          end
          job.processing_status = "Stopped"
          job.processing_log << "Stopped"
          job.save
        else
          job.processing_status = "Stopped"
          job.processing_log << "Job #{job.name} aborted."
          job.save
        end
      else
        logger.info("Submitted Job has been removed before exeuction.")
      end
    rescue Exception => boom
      job = SimulateJob.find(simulate_job_id)
      if job
        job.processing_status = "Stopped"
        job.processing_log << "Stopped because of #{VehicleJourney.html_escape(boom)}"
        job.save
      end
    end
  end

  def failure(job)
  end
end