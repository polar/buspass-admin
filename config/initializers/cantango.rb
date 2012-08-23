##
# Cantango is our authorization implementation. The rules can be
# found in /app/permits
#
# We are using this gem because it handles Roles, although it's
# pretty cumbersome, and could probably go with a simpler solution
# for what we are doing.
#
# TODO: Reevaluate using Cantango for authorization. Declarative Authorization may be better.
#

CanTango.config do |config|

  # I'm not sure if all we need is the PermitEngine.
  #
  config.engines.all :on

  # The permit engine needs to not have a cache.
  # I don't know why at this point. It fails with a "no key".
  config.engine(:permit) do |engine|
    engine.mode = :no_cache
  end

  #
  # Everyone of our "users" has roles. This is the method Cantango uses on
  # our User models
  #
  config.roles.has_method = :has_role?

  # Debugging prints out a lot of stuff that isn't really useful.
  #config.debug.set :on

  # Customers apply to the front website.
  config.users.register :customer, Customer

  # MuniAdmins and Users work with the Masters.
  config.users.register :muni_admin, MuniAdmin
  config.users.register :user, User

  # We seem to need this for anonymous requests.
  config.guest.user = Guest.new
end
