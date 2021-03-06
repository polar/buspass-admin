
##
# This class represents a serializable object that gets passed to
# Delayed Job.
#
# This will copy the contents of a network to a new network.
#
class CopyNetworkJob < Struct.new(:from_network_id, :to_network_id)
  include PageUtils

  def logger
    Rails.logger
  end

  def say(text, level = Logger::INFO)
    text = "[Copy Network] #{text}"
    puts text unless @quiet
    logger.add level, "#{Time.now.strftime('%FT%T%z')}: #{text}" if logger
  end


  def enqueue(job)
    say "Network.id #{network_id} token #{token}"
    net = Network.find(network_id)
    net.copy_job = job
    net.save
  end

  def perform
    say "Copy from Network.id #{from_network_id} to Network.id #{to_network_id}"
    net = Network.find(from_network_id)
    tonet = Network.find(to_network_id)

    if !net
      say "Source network does not exist."
      return
    end

    if !tonet
      say "Destination network does not exist."
      return
    end

    begin
      Network.copy_content(net, tonet)
      create_master_deployment_network_page(tonet.master, tonet.deployment, tonet)
    rescue Exception => boom
      say "Cannot copy network to selected deployment: #{boom}"
    end

  ensure
    net.copy_job = nil
    net.save
    say "Ending Copy Job"
  end

end