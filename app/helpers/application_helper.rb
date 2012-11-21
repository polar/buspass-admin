
module ApplicationHelper

  #
  # For the way we handle the represent time.
  #
  def to_time_literal(time, sep = ":")
    timem = (time - Time.parse("0:00"))/60  # could be negative
                                            # If time is greater than 24 hours, we need to add 24 hours to time.
    dtime = (timem/(60*24)).to_i.abs*24  # hours to add
    hours = (Time.parse("0:00") + timem.minutes).hour + dtime
    mins  = (Time.parse("0:00") + timem.minutes).min
    (timem < 0 ? "~" : "") + ("%02i" % hours) + sep + ("%02i" % mins)
  end

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

  def render_page(site, error_site, path)
    error_page = nil
    error = true
    exception = nil
    begin
      page = site.pages.find_by_full_path(path)
      if page
        result = page.render(self, :status => 200, :content_type => 'text/html')
        error = false
        result
      else
        raise "Could not find page for path: #{path}"
      end
    rescue CanCan::AccessDenied => boom
      exception = boom
      error_page = error_site.pages.find_by_slug("permission_denied")
    rescue NotFoundError => boom
      exception = boom
      error_page = error_site.pages.find_by_slug("not_found")
    rescue => boom
      exception = boom
      page_error = PageError.new({
          :request_url => request.url,
          :params => params,
          :error => boom.to_s,
          :backtrace => boom.backtrace,
          :master => @master,
          :customer => current_customer,
          :muni_admin => current_muni_admin,
          :user => current_user
      })
      page_error.save
      logger.detailed_error(boom)
      error_page = error_site.pages.find_by_slug("internal_error")
    ensure
      if error
        if error_page
          result = error_page.render(self, :status => error_page.error_status, :content_type => "text/html")
        else
          page_error = PageError.new({
                                         :request_url => request.url,
                                         :params     => params,
                                         :error      => "Could not find any error pages #{exception}",
                                         :backtrace  => exception ? exception.backtrace : [],
                                         :master     => @master,
                                         :customer   => current_customer,
                                         :muni_admin => current_muni_admin,
                                         :user       => current_user
                                     })
          page_error.save
          result = render :text => I18n.t('cms.content.page_not_found'), :status => 404
        end
      end
    end
    return result
  end

  def main_render_page(path)
    @site = Cms::Site.find_by_identifier("busme-main")
    @error_site = Cms::Site.find_by_identifier("busme-main-error")
    render_page(@site, @error_site, path)
  end

  def master_admin_render_page(path)
    @site = @master.admin_site
    @error_site = @master.error_site
    render_page(@site, @error_site, path)
  end

  def master_render_page(path)
    @site = @master.main_site
    @error_site = @master.error_site
    render_page(@site, @error_site, path)
  end
end
