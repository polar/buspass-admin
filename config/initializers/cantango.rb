CanTango.config do |config|
  config.engines.all :on
  # more configuration here...

  config.engine(:permit) do |engine|
    engine.mode = :no_cache
  end
  config.roles.has_method = :has_role?

  config.debug.set :on
  #config.models.exclude :admin, :muni_admin
  #config.enable_helpers :rest
  config.users.register :customer, Customer
  config.users.register :muni_admin, MuniAdmin
  config.users.register :user, User
  config.guest.user = Guest.new
end
