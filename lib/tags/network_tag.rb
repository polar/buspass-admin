require "tags/tag"

class NetworkTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier = /[\w\/\-\:]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:bus:deployment:network(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "name"
        @network.name
      when "slug"
        @network.slug
      when "services:count"
        "#{@network.services.count}"
      when "routes:count"
        "#{@network.routes.count}"
      when "journeys:count"
        "#{@network.journeys.count}"
      when "page"
        "<%= render :partial => 'masters/municipalities/networks/show' %>"
      when nil
        "<%= render :partial => 'masters/municipalities/networks/show' %>"
      when ""
        "<%= render :partial => 'masters/municipalities/networks/show' %>"
      else
        "<%= render :partial => 'masters/municipalities/networks/#{identifier}' %>"
    end
  end
end