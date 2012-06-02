class MunicipalityTag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:bus:(?:municipality|deployment)\s*\}\}/
  end

  def content
    if /deployments\/#{page.slug}$/ =~ page.full_path
      master = page.master
      municipality = page.municipality
      slug = municipality.slug
      locals = {
          :master_id => master.id,
          :municipality_id => municipality.id,
      }
      "<%= render :partial => 'masters/municipalities/show', :locals => #{locals.inspect} %>"
    else
      "<%= render :text => 'Deployment for page at #{page.full_path} not found.' %>"
    end
  end

  def render
    content
  end

end