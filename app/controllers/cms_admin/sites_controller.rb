class CmsAdmin::SitesController < CmsAdmin::BaseController

  skip_before_filter  :load_admin_site,
                      :load_fixtures

  before_filter :build_site,  :only => [:new, :create]
  before_filter :load_site,   :only => [:edit, :update, :destroy]

  def index
    return redirect_to new_cms_admin_site_path if Cms::Site.count == 0
    @site = Cms::Site.find_by_id(session[:site_id])
    ## BUSME: THIS IS THE ONLY CHANGE TO THE SITES CONTROLLER
    @sites = @master ? @master.sites : Cms::Site.all
    if @master
      authenticate_muni_admin!
      authorize_muni_admin!(:manage, Cms::Site)
    else
      authenticate_customer!
      authorize_customer!(:manage, Customer)
    end
  end

  # This doesn't really get used by anybody
  def new
    if @master
      flash[:error] = "Cannot create new site"
      redirect_to cms_admin_sites_path(:master_id => @master.id)
    else
      authenticate_customer!
      authorize_customer!(:create, Cms::Site)
      render
    end
  end

  def edit
    if @master
      authenticate_muni_admin!
      authorize_muni_admin!(:edit, Cms::Site)
    else
      authenticate_customer!
      authorize_customer!(:edit, Cms::Site)
    end
    render
  end

  def create
    authenticate_customer!
    authorize_customer!(:create, Cms::Site)
    @site.save!
    flash[:notice] = I18n.t('cms.sites.created')
    redirect_to cms_admin_site_layouts_path(@site)
  rescue ComfortableMexicanSofa.ModelInvalid
    logger.detailed_error($!)
    flash.now[:error] = I18n.t('cms.sites.creation_failure')
    render :action => :new
  end

  def update
    if @master
      authenticate_muni_admin!
      authorize_muni_admin!(:edit, Cms::Site)
    else
      authenticate_customer!
      authorize_customer!(:edit, Cms::Site)
    end

    @site.update_attributes!(params[:site])
    if @master
      authorize_muni_admin!(:edit, @master)
    end

    flash[:notice] = I18n.t('cms.sites.updated')
    redirect_to edit_cms_admin_site_path(@site)
  rescue ComfortableMexicanSofa.ModelInvalid
    logger.detailed_error($!)
    flash.now[:error] = I18n.t('cms.sites.update_failure')
    render :action => :edit
  end

  # This doesn't get used by a MuniAdmin.
  def destroy
    authenticate_customer!
    authorize_customer!(:delete, Cms::Site)
    @site.destroy
    flash[:notice] = I18n.t('cms.sites.deleted')
    redirect_to cms_admin_sites_path
  end

protected

  def build_site
    @site = Cms::Site.new(params[:site])
    @site.hostname ||= request.host.downcase
  end

  def load_site
    @site = Cms::Site.find(params[:id])
    if @site
      @master = @site.master
    end
    raise ComfortableMexicanSofa.ModelNotFound if @site.nil?
    I18n.locale = ComfortableMexicanSofa.config.admin_locale || @site.locale
  rescue ComfortableMexicanSofa.ModelNotFound
    flash[:error] = I18n.t('cms.sites.not_found')
    redirect_to cms_admin_sites_path
  end

end
