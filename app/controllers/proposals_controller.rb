class ProposalsController < ApplicationController
  
  before_filter :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]

  def create
    current_user.update_balance_from_blockchain if @api_status
    @proposal = Proposal.new(proposal_params)
    if @proposal.save
      flash[:notice] = 'Your proposal has been submitted! Now, you can pledge some of your Temps to it.'
      redirect_to proposals_path
    else
      flash[:error] = 'There was an error saving your proposal'
    end

  end
  
  def destroy
    @proposal = Proposal.find(params[:id])
    if @proposal.user != current_user && !current_user.has_role?(:admin)
      flash[:error] = "You cannot delete someone else's proposal."
      redirect_to @proposal
    else
      @proposal.destroy
      flash[:notice] = 'Your proposal was deleted.'
      redirect_to proposals_path
    end
  end
      
  def edit
    @proposal = Proposal.find(params[:id])
    current_user.update_balance_from_blockchain if @api_status
    @current_rate = Rate.get_current.experiment_cost
    if @proposal.user != current_user && !current_user.has_role?(:admin)
      flash[:error] = "You cannot edit someone else's proposal."
      redirect_to @proposal
    end
    set_meta_tags title: 'Edit proposal'
  end
  
  def index
    @next_meeting = Instance.next_meeting
    @current_rate = Rate.get_current.experiment_cost
    @proposals = Proposal.all.order(updated_at: :desc)
    set_meta_tags title: 'Proposals'
  end

  def new
    if current_user.email =~ /change@me/
      flash[:error] = 'You must enter a valid email address in order to propose an experiment.'
      redirect_to proposals_path
    else
      current_user.update_balance_from_blockchain if @api_status
      @current_rate = Rate.get_current.experiment_cost
      @proposal = Proposal.new(user: current_user)
    end
    set_meta_tags title: 'New proposal'
  end
  
  def show
    @current_rate = Rate.get_current.experiment_cost
    @proposal = Proposal.find(params[:id])
    set_meta_tags title: @proposal.name
  end
  
  def update
    @proposal = Proposal.find(params[:id])
    if @proposal.user != current_user && !current_user.has_role?(:admin)
      flash[:error] = "You cannot edit someone else's proposal."
      redirect_to @proposal
    else
      if @proposal.update_attributes(proposal_params)
        flash[:notice] = 'Your proposal has been edited!'
        redirect_to proposals_path
      else
        flash[:error] = 'There was an error saving your edited proposal.'
      end
    end
  end
  
  protected
  
  def proposal_params
    params.require(:proposal).permit(:user_id, :name, :recurrence, :intended_sessions, :stopped, :short_description, :timeframe, :goals,:intended_participants,
                                      images_attributes: [:image, :_destroy, :proposal_id, :id, :remove_image])
  end
  
end