require "tags/tag"

class MuniAdminsTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    /\{\{\s*cms:bus:muni_admins(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "registrations"
        "<%= render :partial => 'masters/muni_admins_devise/registrations/new' %>"
      when "sessions"
        "<%= render :partial => 'masters/muni_admins_devise/sessions/new' %>"
      when "page"
        "<%= render :partial => 'masters/muni_admins/index' %>"
      when nil
        "<%= render :partial => 'masters/muni_admins/index' %>"
      when ""
        "<%= render :partial => 'masters/muni_admins/index' %>"
      else
        "<%= render :partial => 'masters/muni_admins/#{identifier}' %>"
    end
  end

  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end