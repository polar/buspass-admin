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
      when "routes"
        "<%= render :partial => 'masters/municipalities/networks/routes/index' %>"
      when "route"
        "<%= render :partial => 'masters/municipalities/networks/routes/show' %>"
      when "services"
        "<%= render :partial => 'masters/municipalities/networks/services/index' %>"
      when "service"
        "<%= render :partial => 'masters/municipalities/networks/services/show' %>"
      when "journeys"
        "<%= render :partial => 'masters/municipalities/networks/vehicle_journeys/index' %>"
      when "journey"
        "<%= render :partial => 'masters/municipalities/networks/vehicle_journeys/show' %>"

      when "plan"
        "<%= render :partial => 'masters/municipalities/networks/plan/show' %>"
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