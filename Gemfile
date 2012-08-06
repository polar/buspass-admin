source 'https://rubygems.org'

gem 'rails', '3.2.3'

group :assets do
  gem 'sass-rails',   '~> 3.2.4'
  gem 'coffee-rails', '~> 3.2.2'
  gem 'uglifier', '>= 1.2.3'
end

# I'm not sure if this gem is needed with Rails 3.2.3

gem 'jquery-rails'

# The following gem is required to parse HTML using XPath.

gem 'hpricot'

# The following gem is required to parse and create CSV files.

gem "fastercsv"

# The following gems are for using MongoMapper ORM

gem "bson_ext", ">= 1.3.1"
gem "mongo_mapper"

# The following gems handle users and the login registration process

gem "devise", ">= 2.0.0"
gem 'devise-mongo_mapper', :path => "/home/polar/src/devise-mongo_mapper"

# The following gem supplies with String.to_url

gem 'stringex'

# The following gem is being used for our Authorization Framework.

gem 'cantango'

# The following gems are used to handle file uploads

gem "carrierwave"
gem "mm-carrierwave"   # Using the MongoMapper ORM

# The following gems are required for handling zip files.

gem "libarchive"  # requires apt-get install libarchive-dev
gem "zipruby"

# The following gems are required for stats processing in the
# VehicleJourney location processing.

gem "statsample"
gem "statistics2"
gem "clbustos-rtf" #, "~> 0.4.2"

# The following gems are required for handling background
# processing.

gem "delayed_job", :path => "/home/polar/src/delayed_job"
gem "delayed_job_mongo_mapper", :git => "git://github.com/polar/delayed_job_mongo_mapper.git"
gem "daemons"
gem "rush"

# The following gem is the particular Content Management System we are using

gem "comfortable_mexican_sofa",  :path => "/home/polar/src/comfortable-mexican-sofa" # :git => "git://github.com/polar/comfortable-mexican-sofa.git", :branch => "mongo_mapper"

# Not really sure if the following gems are needed.

gem 'cantango_editor', :git => "git://github.com/stanislaw/cantango_editor.git"
gem 'meta_search', '>=1.1.0.pre'
#gem "mm-optimistic_locking"
#gem "validates_timeliness"


# The following gems are required to handle our paging of long lists.

gem "will_paginate"
gem 'will_paginate-bootstrap'

# The following gem is used to handle javascript dynamic form validations

gem "client_side_validations" #, :git => "https://github.com/bcardarella/client_side_validations.git"


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
end

#
# Debugging Gems
#
group :development do
  gem "rspec-rails", ">= 2.8.1"
  gem 'linecache19', "0.5.13"
  gem 'ruby-debug-base19x', '0.11.30.pre10'
  gem 'ruby-debug-ide'
end
