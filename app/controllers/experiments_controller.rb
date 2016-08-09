class ExperimentsController < ApplicationController
  
  def index
    @experiments = Experiment.published.order(end_at: :desc)
  end
  
  def show
    @experiment = Experiment.friendly.find(params[:id])
  end

end
    