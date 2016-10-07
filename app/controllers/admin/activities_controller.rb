class Admin::ActivitiesController < Admin::BaseController
  skip_load_and_authorize_resource
  load_and_authorize_resource
  
  def destroy
    @activity = Activity.find(params[:id])
    if @activity.destroy
      redirect_to '/admin'
    end
  end
  
end