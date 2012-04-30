class MastersBaseController < ApplicationController

  before_filter :authenticate_admin!, :except => [:index, :show, :deployment, :testament]

  layout "masters/normal-layout"

  def authorize!(action, obj)
    raise CanCan::AccessDenied if admin_cannot?(action, obj)
  end

end