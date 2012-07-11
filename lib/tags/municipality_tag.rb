require "tags/tag"

class MunicipalityTag  <Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:bus:deployment(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "name"
        @municipality.name
      when "slug"
        @municipality.slug
      when "location"
        @municipality.location
      when "owner"
        @municipality.owner.name
      # Unfortunately, the identifier catches the NetworkTag depending on when the tags' regexes are scanned
      when "network"
        "<%= render :partial => 'masters/municipalities/networks/show' %>"
      when "networks"
        "<%= render :partial => 'masters/municipalities/networks/index' %>"
      when "simulate"
        "<%= render :partial => 'masters/municipalities/simulate/map' %>"
      when "page"
        "<%= render :partial => 'masters/municipalities/show' %>"
      when nil
        "<%= render :partial => 'masters/municipalities/show' %>"
      when ""
        "<%= render :partial => 'masters/municipalities/show' %>"
      else
        "<%= render :partial => 'masters/municipalities/#{identifier}' %>"
    end
  end
  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end