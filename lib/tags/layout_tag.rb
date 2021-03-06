require "tags/tag"

class LayoutTag    < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:layout(?::(#{identifier})?)\s*\}\}/

  end

  def content
    setup
    case identifier
      when "left"
        "<% content_for :left do %>{{ cms:page:left:text }}<% end %>"
      when "bottom"
        "<% content_for :bottom do %>{{ cms:page:bottom:rich_text }}<% end %>"
      else
        ""
    end
  end
  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end

end