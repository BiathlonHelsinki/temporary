class Admin::BaseController < ApplicationController
  layout 'admin'
  before_action :force_english

  before_action :authenticate_user!
  before_action :authenticate_admin!
  load_and_authorize_resource except: [:home, :proposal, :reports, :resubmit, :delete_nfc, :toggle_key, :respend, :retransfer], find_by: :slug
  
  def authenticate_admin!
    redirect_to root_path unless current_user.has_role? :admin
  end
  
  def check_permissions
    authorize! :create, resource
  end
  
  def toggle_key
    @nfc = Nfc.find(params[:id])
    @nfc.toggle!(:keyholder)
    redirect_to @nfc.user
  end
  
  def delete_nfc
    @nfc = Nfc.find(params[:id])
    user = @nfc.user
    if @nfc.destroy
      flash[:message] = 'Card deleted from database'
    else
      flash[:error] = 'There was an error deleting this card.'
    end
    redirect_to user
  end

  
  
  def reports
    @most_giving = User.all.sort_by{|y| y.pledges.sum(&:pledge) }.reverse
    @richest = User.all.order(latest_balance: :desc).limit(40)
    #@most_earned = Activity.where(addition: 1).group_by(&:user).map{|x| [x.first.display_name, x.last.sum(&:value) ] }.sort_by{|x| x.last}.reverse
    @generous = Activity.where(addition: 1).group_by(&:user).map{|x| [x.first, x.last.sum(&:value), x.first.pledges.sum(&:pledge)]}.sort_by{|x| (x.last.to_f/x[1].to_f) }.reverse
    @stingiest = @generous.reverse
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
  
  def retransfer
    activity = Activity.find(params[:id])
    sender = activity.item
    if sender.class != User
      flash[:error] = 'Error, this activity was not a transfer'
    else
      if @api_status == false || @dapp_status == false
        flash[:error] = 'The Biathlon API is currently down. Please try again later.'
        redirect_to '/admin'
      else
        amount = activity.ethtransaction.value
        if sender.available_balance < amount.to_i
          flash[:error] = 'You cannot do that.'
          redirect_to '/admin'
        else
          api = BiathlonApi.new
        
          success = api.api_post("/users/#{activity.user_id}/transfers/send_biathlon",
                               {user_email: sender.email, 
                                user_token: sender.authentication_token,
                                points: amount,
                                reason: activity.extra_info.gsub(/\s*\(reason\:\s*/, '').gsub(/\)$/, '')
                                })
          if success['error']
            flash[:error] = success['error']
            redirect_to '/admin'
          else
            #activity.ethtransaction = Ethtransaction.find_by(txaddress: success['data'])
            if activity.destroy
              #TransfersMailer.received_temps(current_user, @recipient, params[:temps_to_send], params[:reason]).deliver                   
              flash[:notice] = 'Your re-transfer was successful, thank you!'
              redirect_to '/admin'
            else
              flash[:error] = 'error: ' + success.inspect
            end
          end   
        end                     
      end
    end
  end
  
  def force_english
    I18n.locale = 'en'
  end
  
  def home
    @failed_transactions = Ethtransaction.unconfirmed.order(timeof: :desc)
    @missing_transactions = Activity.where(addition: 1).or(Activity.where(addition: -1)).where(ethtransaction_id: nil)
  end


end
  