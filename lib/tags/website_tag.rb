require "tags/tag"

class WebsiteTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    /\{\{\s*cms:bus:website(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "name"
        @master.name
      when "slug"
        @master.slug
      when "timezone"
        @master.timezone
      when "owner"
        @master.owner.name
      when "page"
        "<%= render :partial => 'websites/show' %>"
      when nil
        "<%= render :partial => 'websites/show' %>"
      when ""
        "<%= render :partial => 'websites/show' %>"
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