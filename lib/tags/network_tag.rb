require "tags/tag"

class NetworkTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier = /[\w\/\-]+/
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
      when "services_count"
        "#{@network.services.count}"
      when "routes_count"
        "#{@network.routes.count}"
      when "journeys_count"
        "#{@network.journeys.count}"

      # Unfortunately, the identifier catches the RoutesTag, ServiceTag, and JourneyTag
      # depending on when the tags' regexes are scanned
      when "simulate"
        "<%= render :partial => 'masters/deployments/networks/simulate/map' %>"
      when "routes"
        "<%= render :partial => 'masters/deployments/networks/routes/index' %>"
      when "route"
        "<%= render :partial => 'masters/deployments/networks/routes/show' %>"
      when "services"
        "<%= render :partial => 'masters/deployments/networks/services/index' %>"
      when "service"
        "<%= render :partial => 'masters/deployments/networks/services/show' %>"
      when "journeys"
        "<%= render :partial => 'masters/deployments/networks/vehicle_journeys/index' %>"
      when "journey"
        "<%= render :partial => 'masters/deployments/networks/vehicle_journeys/show' %>"

      when "plan"
        "<%= render :partial => 'masters/deployments/networks/plan/show' %>"
      when "page"
        "<%= render :partial => 'masters/deployments/networks/show' %>"
      when nil
        "<%= render :partial => 'masters/deployments/networks/show' %>"
      when ""
        "<%= render :partial => 'masters/deployments/networks/show' %>"
      else
        "<%= render :partial => 'masters/deployments/networks/#{identifier}' %>"
    end
  end
  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end