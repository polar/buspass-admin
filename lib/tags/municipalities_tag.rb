class MunicipalitiesTag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:bus:(?:municipalities|deployments)(?::(#{identifier}))?\s*\}\}/
  end

  def content
    if identifier.blank?
      "<%= render :partial => 'masters/municipalities/index' %>"
    else
      "<%= render :partial => 'masters/municipalities/show', :locals => { :municipality_slug => '#{identifier}' } %>"
    end
  end

  def render
      content
  end

end