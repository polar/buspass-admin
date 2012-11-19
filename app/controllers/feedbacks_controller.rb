class FeedbacksController < ApplicationController

  def create
    feedback = Feedback.new(params[:feedback])
    feedback.save
  end

  def index
    @feedbacks = Feedback.paginate(params[:feedback])
  end

end