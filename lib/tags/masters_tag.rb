require "tags/tag"

class MastersTag   < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:bus:masters(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "page"
        "<%= render :partial => 'masters/index' %>"
      when nil
        "<%= render :partial => 'masters/index' %>"
      when ""
        "<%= render :partial => 'masters/index' %>"
      else
        "<%= render :partial => 'masters/#{identifier}' %>"
    end
  end
  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end

end