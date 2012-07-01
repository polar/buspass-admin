require "tags/tag"

class RouteTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:bus:deployment:network:route(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "name"
        @route.name
      when "slug"
        @route.slug
      when "page"
        "<%= render :partial => 'masters/municipalities/networks/routes/show' %>"
      when nil
        "<%= render :partial => 'masters/municipalities/networks/routes/show' %>"
      when ""
        "<%= render :partial => 'masters/municipalities/networks/routes/show' %>"
      else
        "<%= render :partial => 'masters/municipalities/networks/routes/#{identifier}' %>"
    end
  end
  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end