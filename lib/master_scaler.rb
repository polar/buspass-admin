require 'rush'

##
# This module gets included into the Delayed::Job class modeling
# what is done in the delayed_job workless gem.
#
# It starts DJ workers by installing after_create callbacks that
# call "script/delayed_job" that sets up a worker in a separate
# process.
#
# Workers are grouped in DJ queues by Master. We set a limit on
# the amount of workers in the Master.
#
module MasterScaler
  #
  # This constant should never really be used, as the
  # limit is stored in the particular Master.
  #
  DEFAULT_MAX_WORKERS  = 3

  def self.included(base)
    base.send :include, InstanceMethods
    base.class_eval do
      # One for Active, One for Testament, One for Processing. Maybe more for extra service
      after_destroy :possibly_end_workers
      after_create :start_workers
      after_update :possibly_end_workers, :unless => Proc.new { |r| r.failed_at.nil? }
    end
  end


  module InstanceMethods
    # The queue is set by Delayed::Job.enqueue() or Object.delay().
    # It is our convention to use the Master's slug for the queue.

    def jobs_count
      Delayed::Job.where(:queue => self.queue, :failed_at => nil).count
    end

    ##
    # This method is called after a Delayed::Job is created as an 'after_create'
    # callback. We will add a new worker if the jobs_count is greater than the
    # number of workers. We use special workers that exit after there are no more jobs
    # in the queue. So, all workers should be at least working on something.
    # Of course, there can be a race condition where the worker is in the process
    # of exiting, and we don't start a new worker because we think the existing
    # worker will pick it up. There really is no simple way to prevent this because
    # we only know at this point how many workers there are by counting strings
    # matching the queue name in the Unix process table. A solution would be to
    # modify Delayed::Worker to put an indicator that we can count on and prevent
    # it from exiting until we clear it to.
    #
    def start_workers
      master = Master.find_by_slug(self.queue)
      max_workers = master ? master.max_workers : DEFAULT_MAX_WORKERS
      jcount = jobs_count # This count includes this job
      wcount = workers_count
      if jcount > wcount && wcount < max_workers
        Rush::Box.new[Rails.root].bash("script/delayed_job start -i workless-#{self.queue}-#{Time.now.to_i} --queues=#{self.queue} --exit_on_zero", :background => true)
        sleep 1
      end
      true
    end

    def possibly_end_workers
      # Workers will exit on their own when they don't have any more jobs in the queue.
      # We do not have to stop them.
      true
    end

    def workers_count
      # We count the number of matching lines
      Rush::Box.new.processes.filter(:cmdline => /delayed_job start -i workless-#{self.queue}|delayed_job.workless-#{self.queue}/).size
    end
  end
end
