require "tags/tag"

class ToolsTag    < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:bus:masters:tools(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when nil
        "<%= render :partial => 'masters/tools/show' %>"
      when "index"
        "<%= render :partial => 'masters/tools/show' %>"
      else
        if params && params.size > 0
          "<%= render :partial => 'masters/tools/#{identifier}/#{params[0]}' %>"
        else
          "<%= render :partial => 'masters/tools/#{identifier}/show' %>"
        end
    end

  end
  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end