CanTango.config do |config|
  config.engines.all :on
  # more configuration here...

  config.engine(:permit) do |engine|
    engine.mode = :no_cache
  end
  config.debug.set :on
  config.users.register :muni_admin, MuniAdmin
  config.users.register :admin, Admin
    #config.guest.user = Guest.new
end
