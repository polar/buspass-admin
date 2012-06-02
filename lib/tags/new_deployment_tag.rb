class NewDeploymentTag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    /\{\{\s*cms:bus:new-deployment\s*\}\}/
  end

  def content
    "<%= render :partial => 'masters/municipalities/new' %>"
  end

  def render
      content
  end

end