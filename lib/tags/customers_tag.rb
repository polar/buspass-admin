require "tags/tag"

class CustomersTag < Tag
  include ComfortableMexicanSofa::Tag

  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    /\{\{\s*cms:bus:customers(?::(#{identifier}))?\s*\}\}/
  end

  def content
    setup
    case identifier
      when "sign_up"
        "<%= render :partial => 'customer_sessions/new' %>"
      when "edit"
        "<%= render :partial => 'customer_sessions/new' %>"
      when "sign_in"
        "<%= render :partial => 'customer_sessions/new' %>"
      when "page"
        "<%= render :partial => 'customers/index' %>"
      when nil
        "<%= render :partial => 'customers/index' %>"
      when ""
        "<%= render :partial => 'customers/index' %>"
      else
        "<%= render :partial => 'customers/#{identifier}' %>"
    end
  end

  # This renders the tag without sanitizing the ERB for our
  # purposes. Only applies to our tags.
  def render
    content
  end
end