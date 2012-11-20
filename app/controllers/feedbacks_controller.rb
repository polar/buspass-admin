class FeedbacksController < ApplicationController
  layout "main-layout"

  def show
    @feedback = Feedback.find(params[:id])
  end

  def create
    feedback = Feedback.new(params[:feedback])
    feedback.save
  end

  def index
    @feedbacks = Feedback.paginate(:page => params[:page], :per_page => 20)
    @feedbacks
  end

end