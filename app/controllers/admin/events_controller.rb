class Admin::EventsController < Admin::BaseController
  
  def create
    @experiment = Event.new(event_params)
    if @experiment.save
      flash[:notice] = 'Event saved.'
      redirect_to admin_events_path
    else
      flash[:error] = "Error saving event!"
      render template: 'admin/events/new'
    end
  end
  
  def destroy
    event = Event.friendly.find(params[:id])
    event.destroy!
    redirect_to admin_events_path
  end
  
  def edit
    @experiment = Event.friendly.find(params[:id])
  end
  
  def index
    @experiments = Event.all.order("string_to_array(sequence, '.', '')::int[] desc")
  end
  
  def new
    @experiment = Event.new
  end
  
  def update
    @experiment = Event.friendly.find(params[:id])
    if @experiment.update_attributes(event_params)
      flash[:notice] = 'Event details updated.'
      redirect_to admin_events_path
    else
      flash[:error] = 'Error updating event'
    end
  end
    
  
  protected
  
  def event_params
    params.require(:event).permit(:published, :place_id, :primary_sponsor_id,  :proposal_id, 
    :secondary_sponsor_id, :cost_euros, :cost_bb, :sequence, :start_at, :end_at, :sequence, :collapse_in_website,
    :parent_id, :image, translations_attributes: [:name, :description, :locale, :id]
    )
  end
  
end