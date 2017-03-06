class Admin::ProposalsController < Admin::BaseController
  skip_load_and_authorize_resource
  load_and_authorize_resource
  def edit
    @proposal = Proposal.find(params[:id])

  end
  
  def update
    @proposal = Proposal.find(params[:id])
    

    if @proposal.update_attributes(proposal_params)
      if @proposal.previous_changes.keys.include?("proposalstatus_id")
        Activity.create(user: current_user, item: @proposal, description: 'changed the status of', extra_info: " to <em>#{@proposal.proposalstatus.nil? ? 'Active' : @proposal.proposalstatus.name}</em>")
        if @proposal.proposalstatus.nil?
          params[:proposal][:comment][:content] = "<em>Status changed to: <strong>Active</strong></em><br /><br/>" + params[:proposal][:comment][:content]
        else
          if @proposal.proposalstatus.slug == 'invalid'
            @proposal.pledges.each do |pledge|
              pledge.destroy!
            end
          end
          params[:proposal][:comment][:content] = "<em>Status changed to: <strong>#{@proposal.proposalstatus.name}</strong></em><br /><br/>" + params[:proposal][:comment][:content]
        end
        @proposal.comments << Comment.create(params[:proposal][:comment].permit!)
      end
      flash[:notice] = 'Proposal details updated.'
      redirect_to admin_proposals_path
    else
      flash[:error] = 'Error updating proposal'
    end
  end
  
  
  def index
    @proposals = Proposal.all.order(id: :desc)
  end
  
  private
  
  def proposal_params
    params.require(:proposal).permit(:name, :proposalstatus_id, :short_description, 
    :goals, :timeframe, :stopped, :intended_participants)
  end

end
