require "tags/tag"

class DeploymentTag  <Tag
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
        @deployment.name
      when "slug"
        @deployment.slug
      when "location"
        @deployment.location
      when "owner"
        @deployment.owner.name
      # Unfortunately, the identifier catches the NetworkTag depending on when the tags' regexes are scanned
      when "network"
        "<%= render :partial => 'masters/deployments/networks/show' %>"
      when "networks"
        "<%= render :partial => 'masters/deployments/networks/index' %>"
      when "simulate"
        "<%= render :partial => 'masters/deployments/simulate/map' %>"
      when "page"
        "<%= render :partial => 'masters/deployments/show' %>"
      when nil
        "<%= render :partial => 'masters/deployments/show' %>"
      when ""
        "<%= render :partial => 'masters/deployments/show' %>"
      else
        "<%= render :partial => 'masters/deployments/#{identifier}' %>"
    end
  end
  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end