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

  #
  # http://syracuse.busme.us/user_sign_in
  # http://syracuse.busme.us/admin/deployments/deployment-1/networks/network-1
  #        ^-- :master_id    ^---  :cms-path
  def master_host_render_cms
    get_master_context
    if @master
      @cms_path = params[:cms_path]
      if /^admin/ =~ @cms_path
        @cms_site = @master.admin_site
        @cms_path = @cms_path.gsub(/^admin/, "/").squeeze("/")
      else
        @cms_site = @master.main_site
        @cms_path = "/#{@cms_path}".squeeze("/")
      end
      @cms_page = @cms_site.pages.find_by_full_path(@cms_path)
    end
    if @cms_page && @cms_page.redirect_path
      redirect_to @cms_page.redirect_path
    else
      render :render_html
    end
  end

  #
  # http://busme.us/syracuse/user_sign_in
  # http://busme.us/syracuse/admin/deployments
  #                 ^-- master_id
  #                          ^-- cms_path
  # http://busme.us/help/help-1
  #                 ^-- master_id
  #                      ^-- cms_path
  def master_render_cms
    get_master_context
    if @master
      @cms_path = params[:cms_path]
      if /^admin/ =~ @cms_path
        @cms_site = @master.admin_site
        @cms_path = @cms_path.gsub(/^admin/,"/").squeeze("/")
      else
        @cms_site = @master.main_site
        @cms_path = "/#{@cms_path}".squeeze("/")
      end
    else
      @cms_path = "#{params[:master_id]}/#{params[:cms_path]}"
      @cms_site = Cms::Site.find_by_identifier("busme-main")
    end
    @cms_page = @cms_site.pages.find_by_full_path(@cms_path)
    if @cms_page.redirect_path
      redirect_to @cms_page.redirect_path
    else
      render :render_html
    end

  end

protected
  def get_master_context
    @master = Master.find_by_slug(params[:master_id])
    @master ||= Master.find(params[:master_id])
  end


  def load_cms_site
    base_host = ENV['BUSME_BASEHOST'] || Rails.application.base_host || "busme.us"
    @cms_path = params[:cms_path]
    @cms_site ||= Cms::Site.find_by_id(params[:cms_site_id]) if params[:cms_site_id]
    if !@cms_site
      host = request.host.downcase
      path = @cms_path
      # http://syracuse.busme.us/path
      # http://busme.us/syracuse/path
      if (host == base_host || host == "localhost")
        # http://busme.us/syracuse/path
        match = "/#{path}/".squeeze("/").match(/^\/([\w\-]+)(\/.*)?\//)
        if match
          master_slug = match[1]
          host = master_slug + ".#{base_host}"
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
