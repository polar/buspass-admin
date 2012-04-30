class SimulateJob
  include MongoMapper::Document

  belongs_to :deployment # if this isn't nil, it is for a deployment.
  belongs_to :master
  belongs_to :municipality

  key :processing_status, String # "Starting", "Running", "StopRequested", Stopping", "Stopped"
  key :processing_log, Array     # of String
  key :processing_started_at, Time
  key :processing_completed_at, Time
  key :sim_time, Time
  key :clock_mult, Integer
  key :duration, Integer
  key :time_zone, String
  belongs_to :delayed_job, :class_name => "Delayed::Job"

  key :please_stop, Boolean


  attr_accessible :master, :master_id, :municipality, :municipality_id, :deployment, :deployment_id, :time_zone

  class AuditLogger < Logger
    def format_message(severity, timestamp, progname, msg)
      "#{msg}\n"
    end
  end

  def initialize(options)
    super
    self.update_attributes(options)
    self.reinitialize()
  end

  def reinitialize()
    self.processing_status       = "Starting"
    self.processing_log          = ["Simulation #{master.name} - #{municipality.name} has been initialized."]
    self.processing_started_at   = nil
    self.processing_completed_at = nil
    self.please_stop             = false
  end

  def is_processing?
    return ! ["Stopped"].include?(processing_status)
  end

  def set_processing_status(status)
    case processing_status
      when "Starting"
        case status
          when "Starting"
          when "Running"
             self.processing_status= status
          when "StopRequested"
            self.processing_status= status
            self.please_stop = true
          when "Stopping"
            self.processing_status= status
          when "Stopped"
            self.processing_status= status
          else
        end
      when "Running"
        case status
          when "Starting"
          when "Running"
            processing_status= status
          when "StopRequested"
            self.processing_status= status
            self.please_stop = true
          when "Stopping"
            self.processing_status= status
          when "Stopped"
            self.processing_status= status
          else
        end
      when "StopRequested"
        case status
          when "Starting"
          when "Running"
          when "StopRequested"
          when "Stopping"
            self.processing_status= status
          when "Stopped"
            self.processing_status= status
          else
        end
      when "Stopping"
        case status
          when "Starting"
          when "Running"
          when "StopRequested"
          when "Stopping"
          when "Stopped"
            self.processing_status= status
          else
        end
      when "Stopped"
        case status
          when "Starting"
          when "Running"
          when "StopRequested"
          when "Stopping"
          when "Stopped"
          else
        end
      else
    end
  end

  def set_processing_status!(status)
      self.set_processing_status(status)
      save!
  end

  def info(s)
    AuditLogger.new(STDOUT).info s
    reload
    self.processing_log << s
    save
  end
end