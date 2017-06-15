class Admin::CreditsController < Admin::BaseController
  skip_load_and_authorize_resource
  load_and_authorize_resource
  has_scope :by_user
  
  def create
    api = BiathlonApi.new

    if params[:credit] && params[:credit][:attachment]
      # data = StringIO.new(Base64.decode64(File.new(params[:credit][:attachment].tempfile)))
      # data.class.class_eval { attr_accessor :original_filename, :content_type }
      # data.original_filename = params[:credit][:attachment][:filename]
      # data.content_type = params[:credit][:attachment][:content_type]
      params[:credit][:attachment] = Base64.encode64(params[:credit][:attachment].tempfile.read)
    end

    success = api.api_post("/credits", {user_email: current_user.email, 
                            user_token: current_user.authentication_token, credit: params[:credit].to_hash})
    if success['error']
      flash[:error] = success['error']
      @credit = Credit.new(credit_params)
      render template: 'admin/credits/new'
    else                           
      flash[:notice] = 'Your credit was accepted, thank you!'
      redirect_to admin_credits_path
    end                        
  end
  
  def destroy
    api = BiathlonApi.new
    success = api.api_delete("/credits/" + params[:id], {user_email: current_user.email, 
                            user_token: current_user.authentication_token})
    if success['error']
      flash[:error] = success['error'] 
    else                           
      flash[:notice] = 'The credit was deleted, thank you!'
    end
    redirect_to admin_credits_path

  end
  
  def edit
    @credit = Credit.find(params[:id])
  end
  
  def index
    @credits = apply_scopes(Credit).all.order(created_at: :desc)
  end
  
  def new
    @credit = Credit.new
  end
  
  def resubmit
    @credit = Credit.find(params[:id])
    api = BiathlonApi.new
    api_request = api.api_post("/credits/#{@credit.id}/resubmit", {user_email: current_user.email, 
                            user_token: current_user.authentication_token})
    if api_request['error']
      flash[:error] = 'Error: ' + api_request['error'] 
    else
      flash[:notice] = 'Re-submitted to blockchain as ' + api_request['data']['txaddress']
    end
           
    redirect_to "/admin"
  end
    
  def update
    @credit = Credit.find(params[:id])
    if @credit.update_attributes(credit_params)
      flash[:notice] = 'Credit details updated.'
      redirect_to admin_credits_path
    else
      flash[:error] = 'Error updating credit'
    end
  end
    
  
  private
  
  def credit_params
    params.require(:credit).permit(:value, :attachment, :user_id, :awarder_id, :description, :ethtransaction_id, :rate_id, :notes)
  end
  
end