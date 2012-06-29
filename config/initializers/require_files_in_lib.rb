#
# Autoload the lib files
#
Dir[Rails.root + 'lib/**/*.rb'].each do |file|
  puts "Loading #{file}"
  require file
end
