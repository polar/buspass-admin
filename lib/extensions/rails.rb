class ActiveSupport::BufferedLogger
  def detailed_error(e)
    error(e.message)
    e.backtrace.each { |line| error line }
  end
end