#
# Autoload the lib files
#
Dir[Rails.root + 'lib/**/*.rb'].each do |file|
  require file
end
