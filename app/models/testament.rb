class Testament
  include MongoMapper::Document

  belongs_to :master
  belongs_to :municipality
  one :simulate_job

  attr_accessible :master, :master_id, :municipality, :municipality_id

  validate :master_consistent

  before_validation :set_master

  def set_master
    master = municipality.master
  end

  def master_consistent
    master == municipality.master
  end


  def status
    simulate_job ? simulate_job.processing_status : "Unrun"
  end

end