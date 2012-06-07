class MainController < ApplicationController
  layout "empty"

  def show
    @site = Cms::Site.find_by_identifier("busme-main")

  end

  def export
    @site = Cms::Site.find_by_identifier("busme-main")

    begin
      ComfortableMexicanSofa::Fixtures.export_all(@site.hostname)
      flash[:notice] = "Site has been exported to 'db/cms_fixtures/#{@site.hostname}'"
    rescue  => boom
      logger.detailed_error(boom)
      flash[:error] = "Site could not be exported due to error. Check logs"
    end
    redirect_to main_path
  end

  def import
    @site = Cms::Site.find_by_identifier("busme-main")

    begin
      ComfortableMexicanSofa::Fixtures.import_all(@site.hostname, @site.hostname)
      flash[:notice] = "Site has been imported from 'db/cms_fixtures/#{@site.hostname}'"
    rescue  => boom
      logger.detailed_error(boom)
      flash[:error] = "Site could not be imported due to error. Check logs"
    end
    redirect_to main_path
  end
end