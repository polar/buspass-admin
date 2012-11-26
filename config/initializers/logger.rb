#
# This definition extends the Heroku Rails Logger.
#

logger_instance = Rails.logger

def logger_instance.detailed_error(e)
  error(e.message)
  e.backtrace.each { |line| error line }
end