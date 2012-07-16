class SimulateJob
  include MongoMapper::Document

  belongs_to :deployment # if this isn't nil, it is for a deployment.
  belongs_to :testament # if this isn't nil, it is for a testament.

  # If one of the above is assigned, both the master and municipality should be nil.
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


  attr_accessible :master, :master_id
  attr_accessible :municipality, :municipality_id
  attr_accessible :deployment, :deployment_id
  attr_accessible :testament, :testament_id
  attr_accessible :time_zone

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

  def name
    name1 = self.master.name if self.master
    name1 ||= self.testament.master.name if self.testament
    name1 ||= self.deployment.master.name if self.deployment
    name2 = self.municipality.name if self.municipality
    name2 ||= self.testament.municipality.name if self.testament
    name2 ||= self.deployment.municipality.name if self.deployment
    "#{name1} - #{name2}"
  end

  def reinitialize()
    self.processing_status       = "Starting"
    # TODO: Change 'Simulation' for actual runs or testaments
    self.processing_log          = ["Simulation #{name} has been initialized."]
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