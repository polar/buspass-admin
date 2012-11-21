class PageErrorsController < ApplicationController
  layout "main-layout"

  def show
    @page_error = PageError.find(params[:id])
    @page = params[:page]
  end


  def index
    @page_errors = PageError.order("created_at desc").paginate(:page => params[:page], :per_page => 10)
    @page_errors
  end

end