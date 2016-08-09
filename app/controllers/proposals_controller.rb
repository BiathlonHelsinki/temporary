class ProposalsController < ApplicationController
  
  before_filter :authenticate_user!
  
  def new
    current_user.update_balance_from_blockchain
    if current_user.latest_balance < 70
      flash[:error] = 'You do not have enough Temporary credits to propose an experiment.'
      redirect_to '/'
    else
      @proposal = Proposal.new
    end
  end
  
  protected
  
  def proposal_params
    
  end
  
end