class Admin::InstancesUsersController < Admin::BaseController
  skip_load_and_authorize_resource
  load_and_authorize_resource
  
  
  def edit
    @instance_user = InstancesUser.find(params[:id])
  end
  
  def index
    @instances_users = InstancesUser.order(id: :desc).page(params[:page]).per(80)
  end
  
  def destroy
    @instance_user = InstancesUser.find(params[:id])
    if @instance_user.destroy
      flash[:notice] = 'Deleted checkin'
      redirect_to '/admin/instances_users'
    end
  end
  
  def update
    @instance_user = InstancesUser.find(params[:id])
    if @instance_user.update_attributes(iu_params)
      flash[:notice] = 'Checkin details updated.'
      redirect_to '/admin/instances_users'
    else
      flash[:error] = 'Error updating checkin'
    end
  end
  protected
  
  def iu_params
    params.require(:instances_user).permit(:instance_id)
  end
  
end