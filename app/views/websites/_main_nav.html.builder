
@site = @master.main_site
@prefix = request.host == "#{BuspassAdmin::Application.base_host}" || request.host == "localhost" ? "#{@master.slug}/" : ""

def do_page(page, xml)
  if page.is_published
    xml.li {
      xml.a page.label, :href =>  url_for("/" + @prefix + @site.path + page.full_path)
    }
    xml.ul do
      page.children.each do |chpage|
        do_page(chpage, xml)
      end
    end
  end
end

xml.ul {
  page = @site.pages.root
  xml.li {
    xml.a page.label, :href =>  url_for("/" + @prefix + @site.path + page.full_path)
  }
  page.children.all.each do |page|
    # We don't process the deployment template because it doesn't show
    # any deployment, and would come up blank.
    do_page(page, xml)
  end
}
