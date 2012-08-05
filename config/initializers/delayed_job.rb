#
# Although the gem takes care of this, these settings in an
# initializer are needed for the script/delayed_job and rake jobs:start
Delayed::Worker.backend= :mongo_mapper
#
# We only want one attempt.
#  TODO: Fix Delayed job so that this is not an automatic ability.
#
# This number means max "retry" attempts.
Delayed::Worker.max_attempts=1
#
# We set the database for the Jobs Collection, no matter what
# database we are using. This allows us to only have several
# workers without having one for each municipality.
# We really should get this from MongoMapper default, but
# not sure if it's initialized yet. We initialize to the
# same DB.
Delayed::Job.set_database_name("#Busme-#{Rails.env}")

#
# Workless 1.0.1 Gem
#    We use a local scaler to handle upscaling workers
#
# We use MongoMapper so, we need this for the autoscaler.
Delayed::Backend::MongoMapper::Job.send(:include, MasterScaler) if defined?(Delayed::Backend::MongoMapper::Job)

