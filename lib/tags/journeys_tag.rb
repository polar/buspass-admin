require "tags/tag"

class JourneysTag   < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:bus:deployment:network:vehicle_journeys\s*\}\}/
  end

  def content
    setup
    "<%= render :partial => 'masters/deployments/networks/vehicle_journeys/index' %>"
  end
  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end

end