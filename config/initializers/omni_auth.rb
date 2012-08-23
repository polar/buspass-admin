Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, 'uLdnGzffvlbCX0sIKpBJtg', 'cekT1OocNuYOoV2apgNerlDBxrzmQllHBnhrrT5I'
  provider :facebook, '458379574194172', '69bb8e7b2655042f4cfd908e1576c08f'
  provider :linkedin, '1wmmzdtesp17', 'yN9ncr9Cwixl43qS'
  provider :google, 'busme.us', 'LelxfeNM_Byuvhv6tU6oGvAh', :scope => "https://www.googleapis.com/auth/userinfo.profile"
end

# Must be strings, not symbols
BuspassAdmin::Application.oauth_providers += ["twitter", "facebook", "linkedin", "google"]

if ENV['RAILS_ENV'] == "development"
  OmniAuth.config.full_host = "http://busme.us:3000"
end
