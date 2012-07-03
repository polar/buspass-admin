require "tags/tag"

class WebsitesTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    /\{\{\s*cms:bus:websites(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "page"
        "<%= render :partial => 'websites' %>"
      when nil
        "<%= render :partial => 'websites' %>"
      when ""
        "<%= render :partial => 'websites' %>"
      else
        "<%= render :partial => 'websites/#{identifier}' %>"
    end
  end

  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end