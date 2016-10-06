class Admin::EthtransactionsController < Admin::BaseController
  
  def destroy
    @ethtransaction = Ethtransaction.find(params[:id])
    if @ethtransaction.confirmed == false
      if @ethtransaction.activity.nil?
        @ethtransaction.destroy
        redirect_to '/admin'
      end
    end
  end

end