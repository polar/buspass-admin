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

# we only expand if we have children that match.
def traverse(page, expanded = [])
  expand = false
  subpages(page).each do |chpage|
    expand ||= chpage.redirect_path == controller.request.fullpath
    expand ||= traverse(chpage, expanded)
  end
  if expand
    expanded << page
  end
  return expand
end

def do_page(page, xml, expanded)
  if page.is_published
    xml.li {
      xml.a page.label, :href => (!page.controller_path.nil? && !page.controller_path.blank?) ? page.redirect_path : "#{@prefix}/#{@site.path}/#{page.full_path}".squeeze("/")
      subpages(page).tap do |pages|
        xml.ul(:class => "#{expanded.include?(page) ? "expanded" : "collapsed"}") do
          pages.each do |chpage|
            do_page(chpage, xml, expanded)
          end
        end if pages.size > 0
      end
    }
  end
end

xml.ul(:id => "sitemap") {
  page = @site.pages.root
  if page
    # Look for pages that may need to be expanded.
    expanded = []
    expand = traverse(page, expanded)
    xml.li() {
      xml.a page.label, :href => (!page.controller_path.nil? && !page.controller_path.blank?) ? page.redirect_path : "#{@prefix}/#{@site.path}/#{page.full_path}".squeeze("/")
    }
    subpages(page).tap do |pages|
      pages.each do |chpage|
        do_page(chpage, xml, expanded)
      end if pages.size > 0
    end
  end
}


