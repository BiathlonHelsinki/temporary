class OpensessionsController < ApplicationController
  
  def show
    @opensession = Opensession.find(params[:id])
    render layout: false
  end
  
  
end