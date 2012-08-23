##
# This is our simple Warden Failure App.
# It merely redirects to the specified path.
#
class WardenFailureApp < ActionController::Metal
  include ActionController::RackDelegation
  include ActionController::Redirecting
  delegate :flash, :to => :request

  def self.call(env)
    @respond ||= action(:respond)
    @respond.call(env)
  end

  def respond
    flash[:notice] = warden_options[:notice]
    redirect_to warden_options[:path]
  end

  def warden
    env['warden']
  end

  def warden_options
    env['warden.options']
  end
end