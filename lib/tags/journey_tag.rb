require "tags/tag"
class JourneyTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:bus:deployment:network:journey(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "name"
        @vehicle_journey.name
      when "slug"
        @vehicle_journey.slug
      when "page"
        "<%= render :partial => 'masters/deployments/networks/vehicle_journeys/show' %>"
      when nil
        "<%= render :partial => 'masters/deployments/networks/vehicle_journeys/show' %>"
      when ""
        "<%= render :partial => 'masters/deployments/networks/vehicle_journeys/show' %>"
      else
        "<%= render :partial => 'masters/deployments/networks/vehicle_journeys/#{identifier}' %>"
    end
  end
  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end