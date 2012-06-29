
@site = Cms::Site.find_by_identifier("busme-main")
@prefix = ""
exclude_links = ["sites-index", 'new-site']

def do_page(page, xml)
  if page.is_published
    xml.li {
      xml.a page.label, :href =>  page.full_path
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
    xml.a page.label, :href =>  page.full_path
    xml.ul {
      page.children.all.each do |page|
        do_page(page, xml) if !exclude_links.include?(page.slug)
      end
    }
  }
  xml.li {
    xml.a "Sites Index", :href => url_for("/sites");
  }
  xml.li {
    xml.a "New Site", :href => url_for("/sites/new");
  }
}
