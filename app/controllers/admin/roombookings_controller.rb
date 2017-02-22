class Admin::RoombookingsController < Admin::BaseController
  skip_load_and_authorize_resource
  load_and_authorize_resource
  

  
  def destroy
    roombooking = Roombooking.find(params[:id])
    roombooking.destroy!
    redirect_to admin_roombookings_path
  end
  
  def edit
    @roombooking = Roombooking.find(params[:id])
  end
  
  def index
    @roombookings = Roombooking.all.order(created_at: :desc)
    set_meta_tags title: 'News'
  end
  
  
  
  def update
    @roombooking = Roombooking.find(params[:id])
    if @roombooking.update_attributes(roombooking_params)
      flash[:notice] = 'Roombooking details updated.'
      redirect_to admin_roombookings_path
    else
      flash[:error] = 'Error updating roombooking'
    end
  end
  protected
  
  def roombooking_params
    params.require(:roombooking).permit(:day, :user_id, :purpose, :ethtransaction_id, :rate_id)
  end
    
end
  