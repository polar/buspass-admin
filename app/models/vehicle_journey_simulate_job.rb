class VehicleJourneySimulateJob < Struct.new(:simulate_job_id, :find_interval, :time_interval, :clock, :mult, :duration)

  def logger
    Rails.logger
  end

  def say(text, level = Logger::INFO)
    text = "[Simulate] #{text}"
    puts text unless @quiet
    logger.add level, "#{Time.now.strftime('%FT%T%z')}: #{text}" if logger
  end

  def enqueue(job)
    sjob = SimulateJob.find(simulate_job_id)
    if sjob
      sjob.delayed_job = job
      sjob.processing_status = "Enqueued"
      sjob.save
    end
  end

  def perform
    begin
      job = SimulateJob.find(simulate_job_id)
      if (job)
        if job.processing_status == "Enqueued"
          VehicleJourney.simulate_all(job.id, find_interval, time_interval, clock, mult, duration)
        end
        job.processing_status = "Stopped"
        job.processing_log << "Stopped"
        job.save
      end
    rescue Exception => boom
      job = SimulateJob.first(options)
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