##
# A Buspass API must inherit from this class. It must respond to "version".
# It must respond to "allowable_calls" with an array
# of strings that layout the allowable calls for the interface,
# which must include "get". All API calls will be given the controller
# as a calling context. The API must at least respond to the "get"
# call.
#
class Apis::Base

  def version
    return "0"
  end

  def allowable_calls
    ["get"]
  end

  def get(controller)
    return nil
  end

end