class Admin::InstancesController < Admin::BaseController
  
  
  def create
    @experiment = Experiment.friendly.find(params[:experiment_id])
    @experiment.instances <<  Instance.new(instance_params)
    if @experiment.save
      flash[:notice] = 'Instance saved.'
      redirect_to admin_experiments_path
    else
      flash[:error] = "Error saving instance!"
      render template: 'admin/instances/new'
    end
  end

  def edit
    @instance = Instance.friendly.find(params[:id])
    @experiment = @instance.experiment
  end
  
  def new
    @experiment = Experiment.friendly.find(params[:experiment_id])
    @instance = Instance.new(experiment: @experiment, cost_bb: @experiment.cost_bb, 
                              sequence: @experiment.instances.blank? ? @experiment.sequence + ".1" :
                              @experiment.instances.sort_by(&:sequence).last.sequence.rpartition(/\./).first + "." + (@experiment.instances.sort_by(&:sequence).last.sequence.rpartition(/\./).last.to_i + 1).to_s,
                              
                               cost_euros: @experiment.cost_euros, 
                              start_at: @experiment.start_at, end_at: @experiment.end_at,
                              place_id: @experiment.place_id, published: @experiment.published, 
                              translations_attributes: [{locale: 'en', name: @experiment.name(:en), 
                                              description: @experiment.description(:en)}])
                                         

  end
  
  def update
    @instance = Instance.friendly.find(params[:id])
    if @instance.update_attributes(instance_params)
      flash[:notice] = 'Instance details updated.'
      redirect_to admin_experiments_path
    else
      flash[:error] = 'Error updating instance'
    end
  end
    
  
  
  protected
  
  def instance_params
    params.require(:instance).permit(:published, :event_id, :place_id, :primary_sponsor_id, :is_meeting, :proposal_id,
    :secondary_sponsor_id, :cost_euros, :cost_bb, :sequence, :start_at, :end_at, :sequence, 
    :parent_id, :image, translations_attributes: [:name, :description, :locale, :id]
    )
  end
  
end