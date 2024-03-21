class TransfersController < ApplicationController
  before_action :authenticate_user!

  def send_temps
    @recipient = User.friendly.find(params[:user_id])

    if @api_status == false #|| @dapp_status == false
      flash[:error] = 'The Biathlon API is currently down. Please try again later.'
      redirect_to(@recipient)
    else
      current_user.update_balance_from_blockchain
      render(template: 'transfers/send_temps')
    end
  end

  def post_temps
    @recipient = User.friendly.find(params[:user_id])
    @photo = params[:userphoto_id].nil? ? nil : params[:userphoto_id]
    if @api_status == false
      flash[:error] = 'The Biathlon API is currently down. Please try again later.'
      if request.xhr?
      else
        redirect_to(@recipient)
      end
    elsif params[:temps_to_send].to_s !~ /\A[-+]?[0-9]*\.?[0-9]+\Z/ || current_user.available_balance < params[:temps_to_send].to_i
      flash[:error] = 'You cannot do that.'
      redirect_to(@recipient)
    else
      api = BiathlonApi.new

      success = api.api_post("/users/#{params[:user_id]}/transfers/send_biathlon",
                             { user_email: current_user.email,
                               user_token: current_user.authentication_token,
                               points: params[:temps_to_send],
                               reason: params[:reason],
                               userphoto_id: @photo })
      if success['error']
        flash[:error] = success['error']
        redirect_to(send_temps_user_transfers_path(@recipient))
      else
        TransfersMailer.received_temps(current_user, @recipient, params[:temps_to_send], params[:reason]).deliver
        flash[:notice] = 'Your transfer was successful, thank you!'
        if request.xhr?
        else
          redirect_to(@recipient)
        end
      end
    end
  end
end
