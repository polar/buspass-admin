require 'rush'


module MasterScaler

  MAX_WORKERS = 3 # One for Active, One for Testament, One for Processing. Maybe more for extra service
                  #
                  # Queue will be named by Master Slug.
                  #

  def self.included(base)
    base.send :include, InstanceMethods
    base.class_eval do
      after_destroy :possibly_end_workers
      before_create :start_workers
      after_update :possibly_end_workers, :unless => Proc.new { |r| r.failed_at.nil? }
    end
  end


  module InstanceMethods
    def jobs_count
      Delayed::Job.where(:queue => self.queue, :failed_at => nil).count
    end

    def start_workers
      if workers < MAX_WORKERS
        Rush::Box.new[Rails.root].bash("script/delayed_job start -i workless-#{self.queue}-1 --queues=#{self.queue}", :background => true)
        Rush::Box.new[Rails.root].bash("script/delayed_job start -i workless-#{self.queue}-2 --queues=#{self.queue}", :background => true)
        Rush::Box.new[Rails.root].bash("script/delayed_job start -i workless-#{self.queue}-3 --queues=#{self.queue}", :background => true)
        sleep 1
      end
      true
    end

    def possibly_end_workers
      unless jobs_count > 0 and workers > 0
        Rush::Box.new[Rails.root].bash("script/delayed_job stop -i workless-#{self.queue}-1", :background => true)
        Rush::Box.new[Rails.root].bash("script/delayed_job stop -i workless-#{self.queue}-2", :background => true)
        Rush::Box.new[Rails.root].bash("script/delayed_job stop -i workless-#{self.queue}-3", :background => true)
      end
      true
    end

    def workers
      Rush::Box.new.processes.filter(:cmdline => /delayed_job start -i workless-#{self.queue}|delayed_job.workless-#{self.queue}/).size
    end
  end
end
