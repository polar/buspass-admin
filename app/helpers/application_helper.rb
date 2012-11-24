
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

  ##
  # This function renders a particular error page given the exception.
  #
  def render_error_page(error_site, prefix, boom)
    if boom.is_a? CanCan::AccessDenied
        error_page = error_site.pages.find_by_full_path("#{prefix}/permission_denied".squeeze("/"))
    elsif boom.is_a? NotFoundError
        error_page = error_site.pages.find_by_full_path("#{prefix}/not_found".squeeze("/"))
    else
        # We record this error since it is so unexpected
        page_error = PageError.new({
                                       :request_url => request.url,
                                       :params     => params,
                                       :error      => boom.to_s,
                                       :backtrace  => boom.backtrace,
                                       :master     => @master,
                                       :customer   => current_customer,
                                       :muni_admin => current_muni_admin,
                                       :user       => current_user
                                   })
        page_error.save
        error_page = error_site.pages.find_by_full_path("#{prefix}/internal_error".squeeze("/"))
    end
    if error_page
      result = error_page.render(self, :status => error_page.error_status, :content_type => "text/html")
    else
      # This is really bad.
      page_error = PageError.new({
                                     :request_url => request.url,
                                     :params     => params,
                                     :error      => "Could not find any error pages #{boom}",
                                     :backtrace  => boom ? boom.backtrace : [],
                                     :master     => @master,
                                     :customer   => current_customer,
                                     :muni_admin => current_muni_admin,
                                     :user       => current_user
                                 })
      page_error.save
      logger.detailed_error(boom)
      result = render :text => I18n.t('cms.content.page_not_found'), :status => 404
    end
  end

  ##
  # Renders a particular page noted by the path in the given site, or an error page from the
  # error site if an error in rendering occurs. This page is rendered within the context of
  # the current view template.
  #
  def render_page(site, error_site, error_prefix, path)
    error_page = nil
    error     = true
    exception = nil
    result    = nil
    begin
      page = site.pages.find_by_full_path(path)
      if page
        result = page.render(self, :status => 200, :content_type => 'text/html')
        result
      else
        raise "Could not find page for path: #{path}"
      end
    rescue Exception => boom
      result = render_error_page(error_site, error_prefix, boom)
    end
    return result
  end

  #
  # These functions are called from the view template and work in conjunction with
  # the rescue handlers in the application controller. They may set @error_in_controller
  # and may set @error_page if it is found for the particular @error_site.
  #

  ##
  # This function is called in templates emanating from controllers that handle the main
  # busme site (i.e. websites and customer managment).
  #
  def main_render_page(path)
    @site = Cms::Site.find_by_identifier("busme-main")
    @error_site = Cms::Site.find_by_identifier("busme-main-error")
    render_page(@site, @error_site, "/", path)
  end

  ##
  # This function is called in templates emanating from controllers that handle the administration
  # of a particular master.
  #
  def master_admin_render_page(path)
    puts "Start render page"
    @site = @master.admin_site
    @error_site = @master.error_site
    render_page(@site, @error_site, "/admins", path).tap do
      puts "End Render Page"
    end
  end

  ##
  # This function is called in templates emanating from controllers that handle the user facing site
  # of a particular master.
  #
  def master_render_page(path)
    @site = @master.main_site
    @error_site = @master.error_site
    render_page(@site, @error_site, "/users", path)
  end

  def conditional_stylesheet_link_tag(*sources)
    puts "conditional_stylesheet_link_tag #{sources.inspect}"
    options = sources.extract_options!
    sources.delete_if do |source|
      Dir.glob(File.join(Rails.root, "app", "assets", "stylesheets", "#{source}.css*")).empty? && Dir.glob(File.join(Rails.root, "public", "assets", "#{source}.css*")).empty?
    end
    stylesheet_link_tag(*(sources + [options])) if !sources.empty?
  end

  def conditional_javascript_include_tag(*sources)
    puts "conditional_javascript_include_tag #{sources.inspect}"
    options = sources.extract_options!
    sources.delete_if do |source|
      Dir.glob(File.join(Rails.root, "app", "assets", "javascripts", "#{source}.js*")).empty? && Dir.glob(File.join(Rails.root, "public", "assets", "#{source}.js*")).empty?
    end
    javascript_include_tag(*(sources + [options])) if !sources.empty?
  end
end
