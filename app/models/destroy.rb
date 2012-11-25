class Destroy

  def self.sites
    Cms::Site.destroy_all
  end

  def self.customers
    Customer.destroy_all
  end

  def self.masters(master = nil)
    m = master.is_a?(Master) ? master : Master.find_by_slug(master) || Master.find_by_id(master)
    if m
      # This should destroy related Cms::Sites, MuniAdmin, and Users
      m.destroy
    end
  end

  def self.users(master = nil)
    if master
      m = master.is_a?(Master) ? master : Master.find_by_slug(master) || Master.find_by_id(master)
      if m
        m.users.each { |u| u.destroy }
      end
    else
      User.destroy_all
    end
  end

  def self.muni_admins(master = nil)
    if master
      m = master.is_a?(Master) ? master : Master.find_by_slug(master) || Master.find_by_id(master)
      if m
        m.muni_admins.each { |u| u.destroy }
      end
    else
      MuniAdmin.destroy_all
    end
  end

  def self.page_errors
    PageError.destroy_all
  end

  def self.feedbacks
    Feedback.destroy_all
  end

  def self.jobs
    Delayed::Job.destroy_all
  end

  def self.activements(master = nil)
    if master
      m = master.is_a?(Master) ? master : Master.find_by_slug(master) || Master.find_by_id(master)
      if m
        m.activement.destroy if m.activement
      end
    else
      Activement.destroy_all
    end
  end

  def self.testaments(master = nil)
    if master
      m = master.is_a?(Master) ? master : Master.find_by_slug(master) || Master.find_by_id(master)
      if m
        m.testament.destroy if m.testament
      end
    else
      Testament.destroy_all
    end
  end

  def self.deployments(master = nil)
    if master
      m = master.is_a?(Master) ? master : Master.find_by_slug(master) || Master.find_by_id(master)
      if m
        m.deployments.each { |d| d.destroy }
      end
    else
      Deployment.destroy_all
    end
  end

  def self.networks()
    Network.destroy_all
  end

  def self.vehicle_journeys()
    VehicleJourney.destroy_all
  end

  def self.locations()
    JourneyLocation.destroy_all
    ReportedJourneyLocation.destroy_all
  end

  def self.authentications(user = nil)
    if user
      user.authentications.each {|a| a.destroy}
    else
      Authentication.destroy_all
    end
  end

  def self.simulate_jobs(master = nil)
    if master
      m = master.is_a?(Master) ? master : Master.find_by_slug(master) || Master.find_by_id(master)
      if m
        m.simulate_jobs.each { |u| u.destroy }
      end
    else
      SimulateJob.destroy_all
    end
  end

  def self.service_table_jobs(master = nil)
    if master
      m = master.is_a?(Master) ? master : Master.find_by_slug(master) || Master.find_by_id(master)
      if m
        m.service_table_jobs.each { |u| u.destroy }
      end
    else
      ServiceTableJob.destroy_all
    end
  end


  def self.all
    customers()
    masters()
    sites()
    page_errors()
    feedbacks()

    # anything left over from bad deletions
    activements()
    testaments()
    authentications()
    jobs()
    service_table_jobs()
    simulate_jobs()
    deployments() # this should take care of networks.
    networks()
    vehicle_journeys()
    locations()
  end
end