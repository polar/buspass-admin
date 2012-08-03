require "tags/tag"

class MasterActiveTag  < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    /\{\{\s*cms:bus:master:active(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "name"
        @master.activement.name if @master.activement
      when "slug"
        @master.activement.slug if @master.activement
      when "timezone"
        @master.activement.timezone if @master.activement
      when "owner"
        @master.activement.owner.name if @master.activement
      when "page"
        "<%= render :partial => 'masters/active/show' %>"
      when nil
        "<%= render :partial => 'masters/active/show' %>"
      when ""
        "<%= render :partial => 'masters/active/show' %>"
      else
        "<%= render :partial => 'masters/active/#{identifier}' %>"
    end
  end
  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end