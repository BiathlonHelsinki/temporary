class Admin::ProposalsController < Admin::BaseController
  skip_load_and_authorize_resource
  load_and_authorize_resource
  def edit
    @proposal = Proposal.find(params[:id])
  end
  
  def update
    @proposal = Proposal.find(params[:id])
    if @proposal.update_attributes(proposal_params)
      flash[:notice] = 'Proposal details updated.'
      redirect_to admin_proposals_path
    else
      flash[:error] = 'Error updating proposal'
    end
  end
  
  
  def index
    @proposals = Proposal.all
  end
  
  private
  
  def proposal_params
    params.require(:proposal).permit(:name, :short_description, :goals, :timeframe, :intended_participants)
  end

end
