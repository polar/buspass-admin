require "tags/tag"

class RouteTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:bus:deployment:network:service(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "name"
        @service.name
      when "slug"
        @service.slug
      when "page"
        "<%= render :partial => 'masters/municipalities/networks/services/show' %>"
      when nil
        "<%= render :partial => 'masters/municipalities/networks/services/show' %>"
      when ""
        "<%= render :partial => 'masters/municipalities/networks/services/show' %>"
      else
        "<%= render :partial => 'masters/municipalities/networks/services/#{identifier}' %>"
    end
  end
end