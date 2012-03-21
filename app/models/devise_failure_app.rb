##
# We extend the Devise::FailureApp so that we can alter the
# sign_in path with the proper master_id
#
class DeviseFailureApp < Devise::FailureApp

  def scope_path
    opts  = {}
    route = :"new_#{scope}_session_path"
    opts[:format] = request_format unless skip_format?

    # Need this option to get Devise to redirect to the correct Municipality
    # when getting a new session for MuniAdmins.
    opts[:master_id] = params[:master_id] if params[:master_id]

    context = send(Devise.available_router_name)

    if context.respond_to?(route)
      context.send(route, opts)
    elsif respond_to?(:root_path)
      root_path(opts)
    else
      "/"
    end
  end
end