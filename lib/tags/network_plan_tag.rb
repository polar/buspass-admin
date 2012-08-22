require "tags/tag"

class NetworkPlanTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier = /[\w\/\-]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:bus:deployment:network:plan(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "name"
        @network.name
      when "slug"
        @network.slug
      when "services_count"
        "#{@network.services.count}"
      when "routes_count"
        "#{@network.routes.count}"
      when "journeys_count"
        "#{@network.journeys.count}"

      when "upload"
        "<%= render :partial => 'masters/deployments/networks/plan/upload' %>"
      when "page"
        "<%= render :partial => 'masters/deployments/networks/plan/show' %>"
      when nil
        "<%= render :partial => 'masters/deployments/networks/plan/show' %>"
      when ""
        "<%= render :partial => 'masters/deployments/networks/plan/show' %>"
      else
        "<%= render :partial => 'masters/deployments/networks/plan/#{identifier}' %>"
    end
  end
  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end