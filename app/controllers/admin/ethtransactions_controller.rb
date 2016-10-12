class Admin::EthtransactionsController < Admin::BaseController
  skip_load_and_authorize_resource
  load_and_authorize_resource
  
  def destroy
    @ethtransaction = Ethtransaction.find(params[:id])
    if @ethtransaction.confirmed == false
      if @ethtransaction.activity.nil?
        @ethtransaction.destroy
        redirect_to '/admin'
      else
        @ethtransaction.activity.destroy
        @ethtransaction.destroy
        redirect_to '/admin'
      end
    end
  end

end