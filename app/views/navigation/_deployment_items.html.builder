@site = @cms_site || @master.admin_site
@prefix = request.host == "#{BuspassAdmin::Application.base_host}" || request.host == "localhost" ? "/#{@master.slug}" : ""
def exclude_links
  []
end
def exclude_matches
  [/\-template$/]
end

def excluded?(page)
  exclude_links.include?(page.slug) || exclude_matches.reduce(false) {|v,m| v || page.slug.match(m)}
end
def subpages(page)
  page.children.order(:position).all.reduce([]) {|v,p| !excluded?(p) && p.is_published ? v + [p] : v}
end

def do_page(page, xml)
  if page.is_published
    xml.li {
      xml.a page.label, :href => (!page.controller_path.nil? && !page.controller_path.blank?) ? page.redirect_path : "#{@prefix}/#{@site.path}/#{page.full_path}".squeeze("/")
      subpages(page).tap do |pages|
        xml.ul do
          pages.each do |chpage|
            do_page(chpage, xml)
          end
        end if pages.size > 0
      end
    }
  end
end

xml.ul(:id => "sitemap") {
  page = @site.pages.find_by_full_path("/")
  xml.li() {
    xml.a "#{@master.name} Top", :href => (!page.controller_path.nil? && !page.controller_path.blank?) ? page.redirect_path : "#{@prefix}/#{@site.path}/#{page.full_path}".squeeze("/")
  }
  page = @site.pages.find_by_full_path("/tools")
  if page
    xml.li() {
      xml.a page.label, :href => (!page.controller_path.nil? && !page.controller_path.blank?) ? page.redirect_path : "#{@prefix}/#{@site.path}/#{page.full_path}".squeeze("/")
      subpages(page).tap do |pages|
        xml.ul() do
          pages.each do |chpage|
            do_page(chpage, xml)
          end
        end if pages.size > 0
      end
    }
  end
  page = @site.pages.find_by_full_path("/deployments/#{@deployment.slug}")
  xml.li() {
    xml.a page.label, :href => (!page.controller_path.nil? && !page.controller_path.blank?) ? page.redirect_path : "#{@prefix}/#{@site.path}/#{page.full_path}".squeeze("/")
    subpages(page).tap do |pages|
      xml.ul(:class => "expanded") do
        pages.each do |chpage|
          do_page(chpage, xml)
        end
      end if pages.size > 0
    end
  }
}
