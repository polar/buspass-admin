CanTango.config do |config|
  config.engines.all :on
  # more configuration here...

  config.engine(:permit) do |engine|
    engine.mode = :no_cache
  end
  config.debug.set :off
    config.guest.user = Guest.new
end
