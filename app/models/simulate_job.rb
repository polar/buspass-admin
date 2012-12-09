class SimulateJob
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  belongs_to :activement # if this isn't nil, it is for a activement.
  belongs_to :testament # if this isn't nil, it is for a testament.

  # If one of the above is assigned, both the master and deployment should be nil.
  belongs_to :master
  belongs_to :deployment

  key :processing_status, String # "Starting", "Running", "StopRequested", Stopping", "Stopped"
  key :processing_log, Array     # of String
  key :processing_started_at, Time
  key :processing_completed_at, Time
  key :sim_time, Time
  key :clock_mult, Integer
  key :duration, Integer
  key :time_zone, String
  key :disposition, String # "active", "test", "simulate"

  belongs_to :delayed_job, :class_name => "Delayed::Job"

  key :please_stop, Boolean

  many :journey_locations
  many :reported_journey_locations
  many :active_journeys, :dependent => :destroy

  attr_accessible :master, :master_id
  attr_accessible :deployment, :deployment_id
  attr_accessible :activement, :activement_id
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
    if activement
      @disposition  = "active"
      @master        = activement.master
      @master_id     = activement.master.id
      @deployment    = activement.deployment
      @deployment_id = activement.deployment.id
    elsif testament
      @disposition = "test"
      @master        = testament.master
      @master_id     = testament.master.id
      @deployment    = testament.deployment
      @deployment_id = testament.deployment.id
    else
      @disposition = "simulate"
      @master    = deployment.master
      @master_id = deployment.master.id
    end
    self.reinitialize()
  end

  def name
    name1 = self.master.name
    name2 = self.deployment.name
    "#{name1} - #{name2}"
  end

  def reinitialize()
    self.processing_status       = "Starting"
    # TODO: Change 'Simulation' for actual runs or testaments
    self.processing_log          = ["#{name} has been initialized."]
    self.processing_started_at   = nil
    self.processing_completed_at = nil
    self.please_stop             = false
    self.delayed_job             = nil
  end

  def is_processing?
    return delayed_job != nil && !["Stopped"].include?(processing_status)
  end

  def is_stopped?
    return ["Stopped"].include?(processing_status)
  end

  def set_processing_status(status)
    case processing_status
      when "Starting"
        case status
          when "Starting"
            # nothing
          when "Enqueued"
            self.processing_status= status
          when "Running"
            self.processing_status= status
          when "StopRequested"
            self.processing_status= status
            self.please_stop = true
          when "Stopping"
            self.processing_status= status
            self.please_stop = true
          when "Stopped"
            self.processing_status= status
            self.please_stop = true
          else
        end
      when "Enqueued"
        case status
          when "Starting"
            self.processing_status= status
          when "Running"
            self.processing_status= status
          when "StopRequested"
            self.please_stop = true
            self.kill
          when "Stopping"
            self.processing_status= status
            self.please_stop = true
          when "Stopped"
            self.processing_status= status
            self.please_stop = true
          else
        end
      when "Running"
        case status
          when "Starting"
            # nothing
          when "Enqueued"
            # nothing
          when "Running"
            processing_status= status
          when "StopRequested"
            self.processing_status= status
            self.please_stop = true
          when "Stopping"
            self.processing_status= status
            self.please_stop = true
          when "Stopped"
            self.processing_status= status
            self.please_stop = true
          else
        end
      when "StopRequested"
        case status
          when "Starting"
            # nothing
          when "Enqueued"
            # nothing
          when "Running"
            # nothing
          when "StopRequested"
             self.please_stop = true
          when "Stopping"
            self.processing_status= status
            self.please_stop = true
          when "Stopped"
            self.processing_status= status
            self.please_stop = true
          else
        end
      when "Stopping"
        case status
          when "Starting"
          when "Enqueued"
          when "Running"
          when "StopRequested"
            self.please_stop = true
          when "Stopping"
            self.please_stop = true
          when "Stopped"
            self.processing_status= status
            self.please_stop = true
          else
        end
      when "Stopped"
        case status
          when "Starting"
          when "Enqueued"
          when "Running"
          when "StopRequested"
            self.please_stop = true
          when "Stopping"
            self.please_stop = true
          when "Stopped"
            self.please_stop = true
          else
        end
      else
    end
  end

  def kill
    destroy_delayed_job()
    self.please_stop = true
    self.processing_status= "Stopped"
  end

  after_destroy :destroy_delayed_job, :destroy_journey_locations

  def destroy_delayed_job
    delayed_job.destroy() if delayed_job
    self.please_stop = true
    delayed_job = nil;
  end

  def destroy_journey_locations
    active_journeys.all.each {|a| a.destroy }
    journey_locations.all.each { |jl| jl.destroy }
    reported_journey_locations.all.each { |rjl| rjl.destroy }
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