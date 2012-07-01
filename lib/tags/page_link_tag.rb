require "tags/tag"

class PageLinkTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:bus:page:link\s+(#{identifier}),\s+?:('(.*?)')\s*\}\}/
  end

  attr_accessor :link_text, :link_path

  def self.initialize_tag(page, tag_signature)
    if match = tag_signature.match(regex_tag_signature)

      path = match[1]
      link_page = page.site.find_by_full_path(path)
      if (link_page)
        path = page.site.path + path
      end

      if match[2]
        text = match[2]
      else
        if (link_page)
          text = page.label
        else
          text = path
        end
      end

      tag = self.new
      tag.page        = page
      tag.link_path   = path
      tag.link_text   = text
      tag
    end
  end

  def content
    setup
    "<%= link_to '#{self.link_text}', '#{self.link_path}' %>"
  end
  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end