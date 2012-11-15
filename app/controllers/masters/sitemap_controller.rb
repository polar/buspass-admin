class Masters::SitemapController < Masters::MasterBaseController

  layout "empty"

  def admin
    get_master_context
    authenticate_muni_admin!
  end

  def main
    get_master_context
    @site = @master.main_site
    authenticate_user!
  end
end