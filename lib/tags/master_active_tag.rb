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
        @master.deployment.name if @master.deployment
      when "slug"
        @master.deployment.slug if @master.deployment
      when "timezone"
        @master.deployment.timezone if @master.deployment
      when "owner"
        @master.deployment.owner.name if @master.deployment
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
end