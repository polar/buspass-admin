class Testament
  include MongoMapper::Document

  belongs_to :master
  belongs_to :deployment
  one :simulate_job

  attr_accessible :master, :master_id, :deployment, :deployment_id

  validate :master_consistent

  before_validation :set_master

  def set_master
    master = deployment.master if deployment
  end

  def master_consistent
    master == deployment.master if deployment
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