class Admin::ProposalsController < Admin::BaseController
  
  def index
    @proposals = Proposal.all
  end
  
end
