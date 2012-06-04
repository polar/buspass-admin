require "tags/tag"

class MunicipalitiesTag    < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:bus:deployments(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "new"
        "<%= render :partial => 'masters/municipalities/new' %>"
      else
        "<%= render :partial => 'masters/municipalities/index' %>"
    end

  end
end