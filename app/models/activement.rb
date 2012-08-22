class Activement
  include MongoMapper::Document

  belongs_to :master
  belongs_to :deployment

  attr_accessible :master, :master_id, :deployment, :deployment_id

  validate :master_consistent

  before_validation :set_master

  one :simulate_job, :dependent => :destroy

  def is_processing?
    simulate_job && simulate_job.delayed_job
  end

  def set_master
    master ||= deployment.master if deployment
  end

  def master_consistent
    master == deployment.master   if deployment
  end

  def status
    simulate_job ? simulate_job.processing_status : "Unrun"
  end

  def can_start?
    ! simulate_job || !simulate_job.is_processing?
  end

  def can_stop?
    simulate_job && simulate_job.is_processing?
  end
end