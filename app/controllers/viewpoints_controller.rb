class ViewpointsController < ApplicationController
  respond_to :html, :js, :json
  before_action :authenticate_user!, except: :index
  
  def create
    @experiment = Experiment.friendly.find(params[:experiment_id])
    @instance = @experiment.instances.friendly.find(params[:instance_id])
    if @instance.userphotos.by_user(current_user).to_a.delete_if{|x| !x.userphotoslot.nil? }.size < 2 || !current_user.userphotoslots.empty.empty?
      if params[:userphoto]
        @u = Userphoto.new(userphoto_params)
        @u.user = current_user
        if @instance.userphotos.by_user(current_user).to_a.delete_if{|x| !x.userphotoslot.nil? }.size == 2
          current_user.userphotoslots.empty.first.userphoto = @u
          
        end
        @instance.userphotos << @u
        @u.save
      end

    end
      
  end
  
  def destroy
    @experiment = Experiment.friendly.find(params[:experiment_id])
    @instance = @experiment.instances.friendly.find(params[:instance_id])
    @u = Userphoto.find(params[:id])
    if @u.user == current_user || current_user.has_role?(:admin)
      @u.destroy
    end
  end
  
  def index
    @instance = Instance.friendly.find(params[:id])
    @experiment = @instance.experiment
    @viewpoints = @instance.viewpoints
  end
  
  def update
    @experiment = Experiment.friendly.find(params[:experiment_id])
    @instance = @experiment.instances.friendly.find(params[:instance_id])
    if params[:userphoto]
      @u = Userphoto.find(params[:id])
      if @u.update_attributes(userphoto_params)

          
      end
    end
  end
  
  protected
  
  def userphoto_params
    params.require(:userphoto).permit(:image, :caption, :credit)
  end
  
    
end