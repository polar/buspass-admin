class Muni::Plan::NetworkplanController < Muni::ApplicationController

  def show
    @networkplan = Network.find(params[:id])
  end
  def display

  end
end