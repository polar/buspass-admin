require "tags/tag"

class PartialTag < Tag
  include ComfortableMexicanSofa::Tag

  #
  # This will make the CMS tag system use our tag.,
  #
  def self.regex_tag_signature(identifier = nil)
    space = /(\s|\&nbsp\;)?/
    /\{\{#{space}*cms:bus:render:.*\}\}/
  end

  # Initializing tag object for a particular Tag type
  # First capture group in the regex is the tag identifier
  def self.initialize_tag(page, tag_signature)
    path_match ||= /[\w\/\-]+/
    space = /(?:\s|\&nbsp\;)/
    regex = /\{\{#{space}*cms:bus:render:(#{path_match})#{space}*(?:\((.*?)\))?#{space}*\}\}/

    # We need the &nbsp; because that comes up in the rich_text editor.

    # Example:  {{ cms:bus:render:masters/network/index("1","2","3") }}
    # Since we are using CSV, the quotes CANNOT have spaces before or after the commas.
    # Should generate
    # <%= render :partial => 'masters/network/index', :locals => { :param_1 => '1', :param_2 => '2', :param_3 => '3'} %>

    if match = tag_signature.match(regex)

      params = begin
        (CSV.parse_line(match[2].to_s, (RUBY_VERSION < '1.9.2' ? ',' : {:col_sep => ','})) || []).compact
      rescue
        []
      end.map{|p| p.gsub(/\\|'/) { |c| "\\#{c}" } }

      tag = self.new
      tag.page        = page
      tag.identifier  = match[1]
      tag.params      = params
      tag
    end
  end

  def content
    setup
    ps = params.collect_with_index{|p, i| ":param_#{i+1} => '#{p}'"}.join(', ')
    "<%= render :partial => '#{identifier}'#{ps.blank?? nil : ", :locals => {#{ps}}"} %>".tap {|x| p x}
  end

  def render
   content
  end

end