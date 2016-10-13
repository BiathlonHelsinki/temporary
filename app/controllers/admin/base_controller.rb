class Admin::BaseController < ApplicationController
  layout 'admin'
  before_action :force_english

  before_action :authenticate_user!
  before_action :authenticate_admin!
  load_and_authorize_resource except: [:home, :proposal, :resubmit, :respend], find_by: :slug
  
  def authenticate_admin!
    redirect_to root_path unless current_user.has_role? :admin
  end
  
  def check_permissions
    authorize! :create, resource
  end
  
  def respend
    api = BiathlonApi.new
    @activity = Activity.find(params[:id])
    api_request = api.api_post("/users/#{@activity.user_id}/respend", {user_email: current_user.email, 
                            user_token: current_user.authentication_token, points: @activity.ethtransaction.value})
    if api_request['error']
      flash[:error] = 'Error: ' + api_request['error'] 
    else
      e = Ethtransaction.find_by(txaddress:api_request['data']['txaddress'])
      if e.nil?
        flash[:error] = 'Resubmitted as ' + api_request['data']['txaddress'] + ' but cannot find in local database'
      else
        old = Ethtransaction.find(@activity.ethtransaction_id)
        @activity.ethtransaction_id = e.id
        @activity.save!
        old.destroy
        flash[:notice] = 'Re-submitted to blockchain as ' + api_request['data']['txaddress']
      end
    end
           
    redirect_to "/admin"
  end

  

  def resubmit
    api = BiathlonApi.new
    @iu = InstancesUser.find(params[:id])
    api_request = api.api_post("/instances/#{@iu.instance_id}/users/#{@iu.user_id}/resubmit/#{params[:id]}", {user_email: current_user.email, 
                            user_token: current_user.authentication_token})
    if api_request['error']
      flash[:error] = 'Error: ' + api_request['error'] 
    else
      flash[:notice] = 'Re-submitted to blockchain as ' + api_request['data']['txaddress']
    end
           
    redirect_to "/admin"
  end
  
  def force_english
    I18n.locale = 'en'
  end
  
  def home
    @failed_transactions = Ethtransaction.unconfirmed.order(timeof: :desc)
    @missing_transactions = Activity.where(addition: 1).or(Activity.where(addition: -1)).where(ethtransaction_id: nil)
  end


end
  