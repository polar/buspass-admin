
module Masters::ApplicationHelper
  include ApplicationHelper

  def master_meta_tags
    render :partial => "masters/master_meta_tags"
  end


end
