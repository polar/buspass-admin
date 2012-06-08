xml.instruct! :xml, :version => '1.0', :encoding => 'UTF-8'

def do_page(page, xml)
  if page.is_published
    xml.li {
      xml.a page.label, :href =>  url_for(page.full_path)
    }
    xml.ul do
      page.children.each do |chpage|
        do_page(chpage, xml)
      end
    end
  end
end

xml.ul {
  @site.pages.roots.each do |page|
    do_page(page, xml)
  end
}
