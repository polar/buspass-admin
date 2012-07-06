@site = @cms_site || @master.admin_site
@prefix = request.host == "busme.us" || request.host == "localhost" ? "/#{@master.slug}" : ""
exclude_links = []
exclude_matches = [/\-template$/]

def do_page(page, xml)
  if page.is_published
    xml.li {
      xml.a page.label, :href =>  page.controller_path ? page.redirect_path : "#{@prefix}/#{@site.path}/#{page.full_path}".squeeze("/")
    xml.ul do
      page.children.order(:position).all.each do |chpage|
        do_page(chpage, xml)
      end
    end if page.children_count > 0
    }
  end
end

xml.ul(:id => "sitemap") {
  page = @site.pages.root
  xml.li {
    xml.a page.label, :href =>  page.controller_path ? page.redirect_path :  "#{@prefix}/#{@site.path}/#{page.full_path}".squeeze("/")
  }

  page.children.order(:position).all.each do |page|
    do_page(page, xml) if !exclude_links.include?(page.slug) && !exclude_matches.reduce(false) {|v,m| v || page.slug.match(m)}
  end
}
