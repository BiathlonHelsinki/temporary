class TransfersController < ApplicationController
  
  before_filter :authenticate_user!
  
  def send_temps
    @recipient = User.friendly.find(params[:user_id])
  end
  
  def post_temps
    api = BiathlonApi.new
    @recipient = User.friendly.find(params[:user_id])
    success = api.api_post("/users/#{params[:user_id]}/transfers/send_biathlon",
                           {user_email: current_user.email, 
                            user_token: current_user.authentication_token,
                            points: params[:temps_to_send],
                            reason: params[:reason]
                            })
    if success['error']
      flash[:error] = success['error']
      redirect_to send_temps_user_transfers_path(@recipient)
    else                           
      flash[:notice] = 'Your token was converted, thank you!'
      redirect_to @recipient
    end                        
  end
  
end