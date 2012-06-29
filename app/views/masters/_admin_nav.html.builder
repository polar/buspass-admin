
@site = @master.admin_site
@prefix = request.host == "busme.us" || request.host == "localhost" ? "#{@master.slug}/" : ""

def do_page(page, xml)
  if page.is_published
    xml.li {
      xml.a page.label,
            :href =>  url_for("/" + @prefix + @site.path + page.full_path),
            :class => page.master_path == request.path ? "selected" : ""
      # Using starts_with? handles expanding all upward parents from the selected.
      # treeview reconfigures this based on whether the ul's are hidden or not.
      xml.ul(:style => request.path.starts_with?(page.master_path) ? "display: inline" : "display: none") do
        page.children.all.each do |chpage|
          do_page(chpage, xml)
        end
      end if page.children_count > 0
    }
  end
end

xml.ul(:id => "admin_site_nav") {
  page = @site.pages.root
  xml.li {
    xml.a page.label, :href =>  url_for("/" + @prefix + @site.path + page.full_path)
    if muni_admin_can?(:manage, MuniAdmin)
      xml.li {
        xml.a "Admin Management", :href => master_muni_admins_path(@master)
      }
    end
    page.children.all.each do |page|
      # We don't process the deployment template because it doesn't show
      # any municipality, and would come up blank.
      do_page(page, xml) if page.slug != "deployment-template"
    end
  }
}
