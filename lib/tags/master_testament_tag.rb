require "tags/tag"

class MasterTestamentTag  < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    /\{\{\s*cms:bus:master:testament(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "name"
        @master.testament.name if @master.testament
      when "slug"
        @master.testament.slug if @master.testament
      when "timezone"
        @master.testament.timezone if @master.testament
      when "owner"
        @master.testament.owner.name if @master.testament
      when "page"
        "<%= render :partial => 'masters/testament/show' %>"
      when nil
        "<%= render :partial => 'masters/testament/show' %>"
      when ""
        "<%= render :partial => 'masters/testament/show' %>"
      else
        "<%= render :partial => 'masters/testament/#{identifier}' %>"
    end
  end
  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end