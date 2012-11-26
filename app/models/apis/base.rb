##
# A Buspass API must inherit from this class. It must respond to "version".
# It must respond to "allowable_calls" with an array
# of strings that layout the allowable calls for the interface,
# which must include "login". All API calls will be given the controller
# as a calling context. The API must at least respond to the "login"
# call.
#
class Apis::Base

  def version
    return "0"
  end

  def allowable_calls
    ["login"]
  end

  def login(controller)
    return nil
  end

end