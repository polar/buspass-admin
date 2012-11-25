class ServiceTableJob
  include MongoMapper::Document
  include MongoMapper::Plugins::IdentityMap

  belongs_to :master
  belongs_to :owner, :class_name => "MuniAdmin"
  belongs_to :network

  key :compile_service_table_job, CompileServiceTableJob
  key :status
  belongs_to :delayed_job, :class_name => "Delayed::Job", :dependent => :destroy

  validates :network, :presence => true
  validates :owner, :presence => true
  validates :master, :presence => true

  def initialize(network, owner)
    self.owner = owner
    self.network = network
    self.master = self.network.master
    self.compile_service_table_job = CompileServiceTableJob.new(network.id, network.processing_token, self.id)
    self.status = "Created"
  end

  def processing_token
    compile_service_table_job.token
  end

  def status!(stat)
    self.status = stat
    self.save
  end

  def enqueue
    self.delayed_job =
        # TODO: Will change Queue to ID
        Delayed::Job.enqueue(:queue => master.slug,
                             :payload_object => compile_service_table_job)
    if self.delayed_job
      self.status = "Enqueued"
    else
      self.status = "Didn't Work"
    end
    self.save
  end
end