class MasterInfoTag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    /\{\{\s*cms:bus:master-info\s*\}\}/
  end

  def content
    "<%= render :partial => 'masters/show' %>"
  end

  def render
    @master = page.master
    content
  end

end