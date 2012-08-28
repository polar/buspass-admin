
require "chronic"

module ClientSideValidations::Middleware
  class Date < Base
    def response
      begin
        if Chronic.parse(request.params[:date]).nil?
           self.status = 404
        else
          self.status = 200
        end
      rescue Exception => boom
        self.status = 404
      end
      super
    end
  end
end
