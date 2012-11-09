class CmsContentController < CmsBaseController
  layout "empty"
  helper ComfortableMexicanSofa.config.preview_helpers

  # Authentication module must have #authenticate method
  #include ComfortableMexicanSofa.config.public_auth.to_s.constantize
  
  before_filter :load_cms_site
  
  def render_html(status = 200)
    load_cms_page
    @master = @cms_site.master
    if @cms_page.redirect_path
      redirect_to @cms_page.redirect_path
    end
  end

  def render_sitemap
    @cms_layout = @cms_site.layouts.find_by_identifier!("default")
    render :content_type => "text/xml"
  end

  def render_css
    load_cms_layout
    render :text => @cms_layout.css, :content_type => 'text/css'
  end

  def render_js
    load_cms_layout
    render :text => @cms_layout.js, :content_type => 'text/javascript'
  end

protected
  
  def load_cms_site
    @cms_path = params[:cms_path]
    @cms_site ||= Cms::Site.find_by_id(params[:cms_site_id]) if params[:cms_site_id]
    if !@cms_site
      host = request.host.downcase
      path = @cms_path
      # http://syracuse.busme.us/path
      # http://busme.us/syracuse/path
      if (host == "busme.us" || host == "localhost")
        # http://busme.us/syracuse/path
        match = "/#{path}/".squeeze("/").match(/^\/([\w\-]+)(\/.*)?\//)
        if match
          master_slug = match[1]
          host = master_slug + ".busme.us"
          path = match[2]
          @cms_site = Cms::Site.find_site(host, path)
          if @cms_site
            @cms_path.gsub!(/^#{master_slug}/, '')
            @cms_path.gsub!(/^\/#{@cms_site.path}/, '')
            @cms_path.to_s.gsub!(/^\//, '')
          end
        end
      else
        # http://syracuse.busme.us/path
        @cms_site = Cms::Site.find_site(host, path)
        @cms_path ||= "/"
        if @cms_site
          @cms_path.gsub!(/^\/#{@cms_site.path}/, '')
          @cms_path.to_s.gsub!(/^\//, '')
        end
      end

      # if the path == "admin" then we cross over.
      if @cms_path == "admin" && @cms_site && @cms_site.master
        @cms_site = @cms_site.master.admin_site
        @cms_path = ""
      end
    end

    @cms_site ||= Cms::Site.find_by_identifier("busme-main")
    I18n.locale = @cms_site.locale
    puts "LOAD_CMS_SITE"
    puts "cms_site = #{@cms_site.inspect}"
    puts "cms_path = #{@cms_path}"
    return @cms_site
  end
  
  def load_cms_page
    @cms_page = @cms_site.pages.published.find_by_full_path!("/#{@cms_path}")
    raise ComfortableMexicanSofa.ModelNotFound if @cms_page.nil?

    return redirect_to(@cms_page.target_page.url) if @cms_page.target_page

  rescue ComfortableMexicanSofa.ModelNotFound
    if @cms_page = @cms_site.pages.published.find_by_full_path('/404')
      render_html(404)
    else
      raise ActionController::RoutingError.new('Page Not Found')
    end
  end

  def load_cms_layout
    @cms_layout = @cms_site.layouts.find_by_identifier!(params[:identifier])
    raise  ComfortableMexicanSofa.ModelNotFound if @cms_layout.nil?
  rescue ComfortableMexicanSofa.ModelNotFound
    render :nothing => true, :status => 404
  end

end
