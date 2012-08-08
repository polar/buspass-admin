require "tags/tag"

class UsersRegistrationsTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    /\{\{\s*cms:bus:users:registrations(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "new"
        "<%= render :partial => 'masters/users_devise/registrations/new' %>"
      when "sign_up"
        "<%= render :partial => 'masters/users_devise/registrations/new' %>"
      when "page"
        "<%= render :partial => 'masters/users_devise/registrations/new' %>"
      when nil
        "<%= render :partial => 'masters/users_devise/registrations/new' %>"
      when ""
        "<%= render :partial => 'masters/users_devise/registrations/new' %>"
      else
        "<%= render :partial => 'masters/users_devise/registrations/#{identifier}' %>"
    end
  end

  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end