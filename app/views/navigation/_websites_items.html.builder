
@site = Cms::Site.find_by_identifier("busme-main")

def exclude_links
  []
end

def exclude_matches
  [/\-template$/,/edit\-customer/]
end

def excluded?(page)
  if page.full_path == "/admin" && customer_cannot?(:manage, Website)
    return true
  end
  exclude_links.include?(page.slug) || exclude_matches.reduce(false) { |v, m| v || page.slug.match(m) }
end

def subpages(page)
  page.children.order(:position).all.reduce([]) { |v, p| !excluded?(p) && p.is_published ? v + [p] : v }
end

def collect_expanded_pages()
  expanded = []
  pages = @site.pages
  pages.each do |page|
    if page.is_published && !expanded.include?(page) && !excluded?(page) && page.redirect_path == controller.request.fullpath
      expanded << page
      parent = page.parent
      while (parent) do
        expanded << parent
        parent = parent.parent
      end
    end
  end
  return expanded
end

def do_page(page, xml, expanded)
  if page.is_published
    xml.li {
      xml.a page.label, :href => (!page.controller_path.nil? && !page.controller_path.blank?) ? page.redirect_path : "#{@site.path}/#{page.full_path}".squeeze("/")
      subpages(page).tap do |pages|
        xml.ul(:class => "#{expanded.include?(page) ? "expanded" : "collapsed"}")  do
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
    expanded = collect_expanded_pages()
    xml.li() {
      xml.a page.label, :href => (!page.controller_path.nil? && !page.controller_path.blank?) ? page.redirect_path : "#{@site.path}/#{page.full_path}".squeeze("/")
    }
    subpages(page).tap do |pages|
      pages.each do |chpage|
        do_page(chpage, xml, expanded)
      end if pages.size > 0
    end
  end
}
