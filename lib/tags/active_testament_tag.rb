require "tags/tag"

class ActiveTestamentTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:bus:active-testament(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when nil
        "<%= render :partial => 'masters/test/show' %>"
      when "page"
        "<%= render :partial => 'masters/test/show' %>"
      else
        "<%= render :partial => 'masters/test/#{identifier}' %>"
    end
  end

end