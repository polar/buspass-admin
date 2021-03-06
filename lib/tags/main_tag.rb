require "tags/tag"

class MainTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier = /[\w\/\-]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:bus:main(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
     "<%= render :partial => 'main/#{identifier}' %>"
  end
  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end