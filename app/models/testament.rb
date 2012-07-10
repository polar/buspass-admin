class Testament
  include MongoMapper::Document

  belongs_to :master
  belongs_to :municipality
  one :simulate_job

  attr_accessible :master, :master_id, :municipality, :municipality_id

  validate :master_consistent

  before_validation :set_master

  def set_master
    master = municipality.master if municipality
  end

  def master_consistent
    master == municipality.master if municipality
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