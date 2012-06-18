require "tags/tag"

class MasterTag  < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    /\{\{\s*cms:bus:master(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "name"
        @master.name
      when "slug"
        @master.slug
      when "timezone"
        @master.timezone
      when "owner"
        @master.owner.name
      when "active"
        "<%= render :partial => 'masters/active/show' %>"
      when "testament"
        "<%= render :partial => 'masters/testament/show' %>"
      when "page"
        "<%= render :partial => 'masters/show' %>"
      when nil
        "<%= render :partial => 'masters/show' %>"
      when ""
        "<%= render :partial => 'masters/show' %>"
      else
        "<%= render :partial => 'masters/#{identifier}' %>"
    end
  end
end