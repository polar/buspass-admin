require "tags/tag"

class ActiveDeploymentTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:bus:active-deployment(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when nil
        "<%= render :partial => 'masters/active/show' %>"
      when "page"
        "<%= render :partial => 'masters/active/show' %>"
      else
        "<%= render :partial => 'masters/active/#{identifier}' %>"
    end
  end

end