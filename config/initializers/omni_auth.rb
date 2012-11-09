#
# BusPass OmniAuth Configuation
#
# NOTE: 2012-08-22: This is temporary and unfit for security as it resides in the GitHub Repository.
# TODO: Invent an initialization scheme to handle configuring these OAuth2 providers
#

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, 'uLdnGzffvlbCX0sIKpBJtg', 'cekT1OocNuYOoV2apgNerlDBxrzmQllHBnhrrT5I'
  provider :facebook, '458379574194172', '69bb8e7b2655042f4cfd908e1576c08f'
  provider :linkedin, '1wmmzdtesp17', 'yN9ncr9Cwixl43qS'
  provider :google, 'busme.us', 'LelxfeNM_Byuvhv6tU6oGvAh', :scope => "https://www.googleapis.com/auth/userinfo.profile"
end

#
# We cannot get OmniAuth to register these, because it is installing Rack middle ware.
# So we just configure the ones we use here. This value is used in the Authentication screens
# for auth selection. They must be strings, not symbols.
#
BuspassAdmin::Application.oauth_providers += ["twitter", "facebook", "linkedin", "google"]

#
# Important!:
#   Some providers like google, need the full host set as they do not accept
#   relative paths for a redirect_url.
#
# NOTE: 2012-08-22: Not sure how this would be handled on Heroku.
# NOTE: 2012-11-09: We do not set the full_host. The full_host, when not set here, will be determined
#       by OmniAuth tfrom Request.uri to /auth/:provider, which is what we want.
#       A request for syracuse.busme.us:3000/auth/google  will get a callback of syracuse:busme.us:30000/auth/google/callback
#       To get the masterid in the call back we use /auth/:provider?master_id=23424234234234
#
