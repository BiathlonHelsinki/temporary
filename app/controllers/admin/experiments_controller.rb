class Admin::ExperimentsController < Admin::BaseController
  
  def create
    @experiment = Experiment.new(experiment_params)
    if @experiment.save
      flash[:notice] = 'Experiment saved.'
      redirect_to admin_experiments_path
    else
      flash[:error] = "Error saving experiment!"
      render template: 'admin/experiments/new'
    end
  end
  
  def destroy
    experiment = Experiment.friendly.find(params[:id])
    experiment.destroy!
    redirect_to admin_experiments_path
  end
  
  def edit
    @experiment = Experiment.friendly.find(params[:id])
  end
  
  def index
    @experiments = Experiment.all.order(start_at: :desc)
  end
  
  def new
    @experiment = Experiment.new
  end
  
  def update
    @experiment = Experiment.friendly.find(params[:id])
    if @experiment.update_attributes(experiment_params)
      flash[:notice] = 'Experiment details updated.'
      redirect_to admin_experiments_controller
    else
      flash[:error] = 'Error updating experiment'
    end
  end
    
  
  protected
  
  def experiment_params
    params.require(:experiment).permit(:published, :place_id, :primary_sponsor_id, 
    :secondary_sponsor_id, :cost_euros, :cost_bb, :sequence, :start_at, :end_at, :sequence, 
    :parent_id, :image, translations_attributes: [:name, :description, :locale, :id]
    )
  end
  
end