class ProposalsController < ApplicationController
  
  before_filter :authenticate_user!, only: [:new, :create, :update, :destroy]

  def create
    current_user.update_balance_from_blockchain
    @proposal = Proposal.new(proposal_params)
    if @proposal.save
      flash[:notice] = 'Your proposal has been submitted!'
      redirect_to proposals_path
    else
      flash[:error] = 'There was an error saving your proposal'
    end

  end
  
  def index
    @next_meeting = Instance.next_meeting
    @current_rate = Rate.get_current.experiment_cost
    @proposals = Proposal.all
  end

  def new
    
    current_user.update_balance_from_blockchain
    @current_rate = Rate.get_current.experiment_cost
    @proposal = Proposal.new(user: current_user)

  end
  
  def show
    @current_rate = Rate.get_current.experiment_cost
    @proposal = Proposal.find(params[:id])
  end
  
  def update
    @proposal = Proposal.friendly.find(params[:id])
    if @proposal.update_attributes(proposal_params)
      flash[:notice] = 'Your proposal has been edited!'
      redirect_to proposals_path
    else
      flash[:error] = 'There was an error saving your edited proposal.'
    end
  end
  
  protected
  
  def proposal_params
    params.require(:proposal).permit(:user_id, :name, :short_description, :timeframe, :goals,:intended_participants,
                                      images_attributes: [:image, :_destroy, :proposal_id, :remove_image])
  end
  
end