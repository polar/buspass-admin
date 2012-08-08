require "tags/tag"

class UsersSessionsTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    /\{\{\s*cms:bus:users:sessions(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "new"
        "<%= render :partial => 'masters/users_devise/sessions/new' %>"
      when "sign_up"
        "<%= render :partial => 'masters/users_devise/sessions/new' %>"
      when "page"
        "<%= render :partial => 'masters/users_devise/sessions/new' %>"
      when nil
        "<%= render :partial => 'masters/users_devise/sessions/new' %>"
      when ""
        "<%= render :partial => 'masters/users_devise/sessions/new' %>"
      else
        "<%= render :partial => 'masters/users_devise/sessions/#{identifier}' %>"
    end
  end

  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end