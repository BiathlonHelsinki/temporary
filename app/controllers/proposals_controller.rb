class ProposalsController < ApplicationController
  
  before_filter :authenticate_user!, only: [:new, :create, :update, :destroy]

  def create
    current_user.update_balance_from_blockchain
    if current_user.latest_balance < 70
      flash[:error] = 'You do not have enough Temporary credits to propose an experiment.'
      redirect_to '/'
    else
      @proposal = Proposal.new(proposal_params)
      if @proposal.save
        flash[:notice] = 'Your proposal has been submitted!'
        redirect_to proposals_path
      else
        flash[:error] = 'There was an error saving your proposal'
      end
    end
  end
  
  def index
    @proposals = Proposal.all
  end

  def new
    current_user.update_balance_from_blockchain
    if current_user.latest_balance < 70
      flash[:error] = 'You do not have enough Temporary credits to propose an experiment.'
      redirect_to '/'
    else
      @proposal = Proposal.new(user: current_user)
    end
  end
  
  def show
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