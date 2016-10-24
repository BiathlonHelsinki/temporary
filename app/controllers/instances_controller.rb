class InstancesController < ApplicationController
  
  def show
    if params[:experiment_id]
      @experiment = Experiment.friendly.find(params[:experiment_id])
      @instance = @experiment.instances.friendly.find(params[:id])
      set_meta_tags title: @instance.name
    end
    
  end
  
  def index
    if params[:experiment_id]
      @experiment = Experiment.friendly.find(params[:experiment_id])
      redirect_to action: action_name, experiment_id: @experiment.friendly_id, status: 301 unless @experiment.friendly_id == params[:experiment_id]
      @future = @experiment.instances.current.or(@experiment.instances.future).order(:start_at).uniq
      @past = @experiment.instances.past.order(:start_at).uniq.reverse
    end
    set_meta_tags title: @experiment.name
  end
  
end