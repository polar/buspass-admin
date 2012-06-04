
module ApplicationHelper


    ##
    # Generic way to handle the Error Messages for Objects
    #
    def error_messages!(resource)
        return "" if resource.errors.empty?

        messages = resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join
        sentence = I18n.t("errors.messages.not_saved",
                            :count => resource.errors.count,
                            :resource => resource.class.model_name.human.downcase)

        html = <<-HTML
        <div id="error_explanation">
            <h2>#{sentence}</h2>
            <ul>#{messages}</ul>
        </div>
        HTML

        html.html_safe
    end

    ##
    # Turns a location, which is a LonLat array of two floats
    # to a string for display.
    #
    def to_location_str(location)
      if location && location.is_a?(Array) && location.length == 2
        return "#{location[0]}, #{location[1]}"
      else
        return ""
      end
    end

    ##
    # Turns an input string into a location array.
    #
    def from_location_str(location)
        if location != nil
            if location.is_a? String
                location = location.split(",")
            end
            if location.is_a? Array
                location = location.map {|x| x.to_f}.take(2)
            end
        end
        return location
    end

end
