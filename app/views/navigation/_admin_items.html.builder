@site = @cms_site || @master.admin_site
@prefix = request.host == "#{@master.base_host}" || request.host == "localhost" ? "/#{@master.slug}" : ""
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
  page.children.order(:position).all.reduce([]) {|v,p| p.is_published &&!excluded?(p) ? v + [p] : v}
end

def collect_expanded_pages()
  expanded = []
  pages = @site.pages
  pages.each do |page|
    if page.is_published && !expanded.include?(page) && !excluded?(page) && page.redirect_path == controller.request.fullpath
      expanded << page
      parent = page.parent
      while(parent) do
        expanded << parent
        parent = parent.parent
      end
    end
  end
  return expanded
end

def do_page(page, xml, level, expanded)
  puts "do_page #{page.slug}"
  if page.is_published
    xml.li {
      xml.a page.label, :href => (!page.controller_path.nil? && !page.controller_path.blank?) ? page.redirect_path : "#{@prefix}/#{@site.path}/#{page.full_path}".squeeze("/")
      subpages(page).tap do |pages|
        xml.ul(:class => "#{expanded.include?(page) ? "expanded" : "collapsed"}") do
          pages.each do |chpage|
            do_page(chpage, xml, level-1, expanded)
          end
        end if pages.size > 0 && level > 0
      end
    }
  end
end

puts "Start Builder"
xml.ul(:id => "sitemap") {
  page = @site.pages.root
  if page
    # Look for pages that may need to be expanded.
    expanded = collect_expanded_pages()
    xml.li() {
      xml.a page.label, :href => (!page.controller_path.nil? && !page.controller_path.blank?) ? page.redirect_path : "#{@prefix}/#{@site.path}/#{page.full_path}".squeeze("/")
    }
    subpages(page).tap do |pages|
      pages.each do |chpage|
        if chpage.slug == "deployments"
          do_page(chpage, xml, 1, expanded)
        else
          if chpage.slug != "admin" || muni_admin_can?(:edit, @master)
            do_page(chpage, xml, 9999, expanded)
          end
        end
      end if pages.size > 0
    end
  end
}

puts "End Builder"

