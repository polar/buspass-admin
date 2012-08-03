class MastersBaseController < ApplicationController

  before_filter :authenticate_customer!, :except => [:index, :show, :activement, :testament]

  layout "empty"

  def authorize!(action, obj)
    raise CanCan::AccessDenied if customer_cannot?(action, obj)
  end

end