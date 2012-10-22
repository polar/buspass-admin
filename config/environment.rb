# Load the rails application
require File.expand_path('../application', __FILE__)

require File.expand_path('../initializers/debug_fix', __FILE__)

# Initialize the rails application
BuspassAdmin::Application.initialize!
