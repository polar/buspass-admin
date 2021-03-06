class CmsAdmin::BaseController  < CmsBaseController

  before_filter :setup
  before_filter :load_admin_site,
                :set_locale,
                #:load_fixtures,
                :except => :jump

  layout 'cms_admin'

  if ComfortableMexicanSofa.config.admin_cache_sweeper.present?
    cache_sweeper *ComfortableMexicanSofa.config.admin_cache_sweeper
  end

  def setup
    @master = Master.find_by_slug(params[:master_id]) if params[:master_id]
    @master ||= Master.find(params[:master_id]) if params[:master_id]
    @deployment = Deployment.find(params[:deployment_id]) if params[:deployment_id]
    @network = Network.find(params[:network_id]) if params[:network_id]
    @route = Route.find(params[:route_id]) if params[:route_id]
    @service = Route.find(params[:service_id]) if params[:service_id]
    @vehicle_journey = Route.find(params[:vehicle_journey_id]) if params[:vehicle_journey_id]
    @site = Cms::Site.find(params[:site_id]) if params[:site_id]
    @master ||= @site.master if @site

    if @master && !@master.cms_admin_allowed
      flash[:error] = "You must sign an agreement with Busme.us to alter your web pages."
      redirect_to main_app.master_path(@master)
    end
  end

  def jump
    path = ComfortableMexicanSofa.config.admin_route_redirect
    return redirect_to(path) unless path.blank?
    if @site
      redirect_to main_app.cms_admin_site_pages_path
    else
      redirect_to main_app.cms_admin_sites_path
    end
  end

  protected

  def load_admin_site
      if @site.nil?
        I18n.locale = ComfortableMexicanSofa.config.admin_locale || I18n.default_locale
        flash[:error] = I18n.t('cms.base.site_not_found')
        return redirect_to(main_app.master_deployments_path(@master))
      end
  end

  def set_locale
    I18n.locale = ComfortableMexicanSofa.config.admin_locale || (@site && @site.locale)
    true
  end

  def load_fixtures
    return unless ComfortableMexicanSofa.config.enable_fixtures
    if %w(cms_admin/layouts cms_admin/pages cms_admin/snippets).member?(params[:controller])
      ComfortableMexicanSofa::Fixtures.import_all(@site.hostname)
      flash.now[:error] = I18n.t('cms.base.fixtures_enabled')
    end
  end
end