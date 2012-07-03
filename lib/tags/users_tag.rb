require "tags/tag"

class UsersTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    /\{\{\s*cms:bus:users(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "page"
        "<%= render :partial => 'masters/users/index' %>"
      when nil
        "<%= render :partial => 'masters/users/index' %>"
      when ""
        "<%= render :partial => 'masters/users/index' %>"
      else
        "<%= render :partial => 'masters/users/#{identifier}' %>"
    end
  end

  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end