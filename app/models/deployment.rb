class Deployment
  include MongoMapper::Document

  belongs_to :master
  belongs_to :municipality

  attr_accessible :master, :master_id, :municipality, :municipality_id

  validate :master_consistent

  before_validation :set_master

  one :simulate_job

  def set_master
    master = municipality.master
  end

  def master_consistent
    master == municipality.master
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