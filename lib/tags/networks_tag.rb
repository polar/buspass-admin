require "tags/tag"

class NetworksTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:bus:deployment:networks(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    setup
    case identifier
      when "new"
        "<%= render :partial => 'masters/deployments/networks/new' %>"
      else
        "<%= render :partial => 'masters/deployments/networks/index' %>"
    end
  end
  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end

end