require "tags/tag"

class ServiceTag < Tag
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
        "<%= render :partial => 'masters/deployments/networks/services/show' %>"
      when nil
        "<%= render :partial => 'masters/deployments/networks/services/show' %>"
      when ""
        "<%= render :partial => 'masters/deployments/networks/services/show' %>"
      else
        "<%= render :partial => 'masters/deployments/networks/services/#{identifier}' %>"
    end
  end
  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end