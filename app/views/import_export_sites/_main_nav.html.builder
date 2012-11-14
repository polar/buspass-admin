@site ||= @cms_site
@prefix = request.host == "busme.us" || request.host == "localhost" ? "websites/" : ""

def do_page(page, xml)
  if page.is_published
    xml.li {
      xml.a page.label, :href =>  url_for("/" + @prefix + @site.path + page.full_path),
            :class => page.master_path == request.path ? "selected" : ""
    }
    xml.ul(:style => request.path.starts_with?(page.master_path) ? "display: inline" : "display: none") do
      page.children.each do |chpage|
        do_page(chpage, xml)
      end
    end if page.children_count > 0
  end
end

xml.ul(:id => "main_site_nav") {
  page = @site.pages.root
  xml.li {
    xml.a page.label, :href =>  url_for("/" + @prefix + @site.path + page.full_path)
    if customer_can?(:manage, Customer)
      xml.li {
        xml.a "Customer Management", :href => customers_path
      }
    end
    page.children.all.each do |page|
      # We don't process the deployment template because it doesn't show
      # any deployment, and would come up blank.
      do_page(page, xml)
    end
  }
}
