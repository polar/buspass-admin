require "tags/tag"

class MuniAdminsSessionsTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    /\{\{\s*cms:bus:muni_admins:sessions(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "sign_in"
        "<%= render :partial => 'masters/muni_admins_devise/sessions/new' %>"
      when "new"
        "<%= render :partial => 'masters/muni_admins_devise/sessions/new' %>"
      when "page"
        "<%= render :partial => 'masters/muni_admins_devise/sessions/new' %>"
      when nil
        "<%= render :partial => 'masters/muni_admins_devise/sessions/new' %>"
      when ""
        "<%= render :partial => 'masters/muni_admins_devise/sessions/new' %>"
      else
        "<%= render :partial => 'masters/muni_admins_devise/sessions/#{identifier}' %>"
    end
  end

  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end