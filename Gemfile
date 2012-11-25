source 'https://rubygems.org'

gem 'rails', '3.2.7'

group :assets do
  gem 'sass-rails',   '~> 3.2.4'
  gem 'coffee-rails', '~> 3.2.2'
  gem 'uglifier', '>= 1.2.3'
end

gem 'compass-rails'

# I'm not sure if this gem is needed with Rails 3.2.3

gem 'jquery-rails'
gem 'spinjs-rails'

# Validates email addresses

gem 'valid_email'

# Proper dealings with timezone names for maps

gem "timezone"
gem "date_validator"
gem "chronic"

# The following gem is required to parse HTML using XPath.

gem 'hpricot'

# The following gems are for using MongoMapper ORM

gem "bson_ext", ">= 1.3.1"
gem "mongo_mapper"

# The following gems handle users and the login registration process

#gem "devise", ">= 2.0.0"
#gem 'devise-mongo_mapper', :path => "/home/polar/src/devise-mongo_mapper"
#gem 'devise-mongo_mapper', :git => "git://github.com/polar/devise-mongo_mapper"
gem "warden"
gem "omniauth-linkedin"
gem "omniauth-openid"
gem "omniauth-twitter"
gem "omniauth-facebook"
gem "omniauth-google"

# The following gem supplies with String.to_url

gem 'stringex'

# The following gem is being used for our Authorization Framework.

gem 'cantango'

# The following gems are used to handle file uploads. We use Carrierwave
# to handle the uploads of PlanFiles, so they get uploaded directly (on Heroku)
# and go away later as we do not keep them.

gem "carrierwave"
gem "mm-carrierwave"   # Using the MongoMapper ORM

# This is needed for Paperclip. We use Paperclip for images and other
# files for the CMS part and upload them to S3.

gem 'aws-sdk'

# The following gems are required for handling zip files.

gem "libarchive-static"
gem "zipruby"

# The following gems are required for stats processing in the
# VehicleJourney location processing.

gem "statsample"
gem "statistics2"
gem "clbustos-rtf" #, "~> 0.4.2"

# The following gems are required for handling background
# processing.

#gem "delayed_job", :path => "/home/polar/src/delayed_job"
gem "delayed_job", :git => "git://github.com/polar/delayed_job"
gem "delayed_job_mongo_mapper", :git => "git://github.com/polar/delayed_job_mongo_mapper.git"
gem "daemons"
gem "rush"

# The following gem is the particular Content Management System we are using

#gem "comfortable_mexican_sofa",  :path => "/home/polar/src/comfortable-mexican-sofa"
gem "comfortable_mexican_sofa",  :git => "git://github.com/polar/comfortable-mexican-sofa.git", :branch => "mongo_mapper"

# Not really sure if the following gems are needed.

gem 'meta_search', '>=1.1.0.pre'
#gem "mm-optimistic_locking"
#gem "validates_timeliness"


# The following gems are required to handle our paging of long lists.

gem "will_paginate"
gem 'will_paginate-bootstrap'

# The following gem is used to handle javascript dynamic form validations

gem "client_side_validations" #, :git => "https://github.com/bcardarella/client_side_validations.git"

gem "mongo_mapper_acts_as_list"

gem 'newrelic_rpm'
#
# Testing Framework gems.
#
group :test do
  gem "rspec-rails", ">= 2.8.1"
  gem "database_cleaner", ">= 0.7.1"
  gem "factory_girl_rails", ">= 1.6.0"
  gem "cucumber-rails", ">= 1.2.1"
  gem "capybara", ">= 1.1.2"
  gem "launchy", ">= 2.0.5"
  gem "debugger" unless ENV["RM_INFO"]
end

#
# Debugging Gems
#
group :development do
  gem "rspec-rails", ">= 2.8.1"
  gem "debugger"  unless ENV["RM_INFO"]
end


#
# Deployment Gems
#

#gem 'capistrano'
gem 'passenger'
gem 'rvm'

gem 'thin'
