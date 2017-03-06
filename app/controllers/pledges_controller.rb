class PledgesController < ApplicationController

  before_filter :authenticate_user!
  
  
  def create
    current_user.update_balance_from_blockchain
    balance = current_user.latest_balance
    @proposal = Proposal.find(params[:proposal_id])
    if !current_user.pledges.unconverted.where(item: @proposal).empty?
      flash[:notice] = 'You already have an unspent pledge towards this proposal. You can edit or delete it but you cannot create a new one.'
      redirect_to @proposal
    else
      if balance < params[:pledge][:pledge].to_i
        flash[:error] = 'You do not have this many ' + ENV['currency_full_name']
        redirect_to new_proposal_pledge_path(@proposal)
      end
      if params[:pledge][:pledge].to_i > @proposal.maximum_pledgeable(current_user)
        flash[:error] = 'You can\'t pledge this much!'
        redirect_to new_proposal_pledge_path(@proposal)
      else
        @pledge = Pledge.new(pledge_params)
        @pledge.item = @proposal
        @pledge.user = current_user
        @pledge.converted = false
        if @pledge.save
          render template: 'pledges/after_pledge'
        else
          flash[:error] = 'There was an error saving your pledge: ' + @pledge.errors.messages.values.join('; ')
          redirect_to @proposal
        end
      end
    end
  end
  
  def destroy
    @item = Proposal.find(params[:proposal_id])
    @pledge = @item.pledges.find(params[:id])
    if @pledge.destroy!
      flash[:notice] = 'Your pledge has been withdrawn.'
      redirect_to @item 
    else
      flash[:error] = "There was an error withdrawing your pledge."
    end
  end
  
  def edit
    @next_meeting = Instance.next_meeting
    @current_rate = Rate.get_current.experiment_cost
    @item = Proposal.find(params[:proposal_id])
    @pledge = @item.pledges.find(params[:id])
    
  end
  
  def new

    @item = Proposal.find(params[:proposal_id])
    if @item.stopped? || !@item.valid?
      flash[:error] = 'This experiment has finished.'
      redirect_to proposals_path
    else
      @next_meeting = Instance.next_meeting
      @current_rate = Rate.get_current.experiment_cost
      if current_user.pledges.unconverted.where(item: @item).empty?
        @pledge = @item.pledges.build
      else
        flash[:notice] = 'You already have an unspent pledge towards this proposal. You can edit or delete it but you cannot create a new one.'
        @pledge = current_user.pledges.unconverted.find_by(item: @item)
      end
    end
  end
  
  
  def update
    @item = Proposal.find(params[:proposal_id])
    @pledge = @item.pledges.find(params[:id])
    if params[:pledge][:pledge].to_i > @item.maximum_pledgeable(current_user)
      flash[:error] = 'You can\'t pledge this much!'
      redirect_to new_proposal_pledge_path(@item)
    else
      if @pledge.update_attributes(pledge_params)
        flash[:notice] = 'Your pledge has been edited!'
        redirect_to @item
      else
        flash[:error] = 'There was an error saving your edited pledge: ' + @pledge.errors.values.join
        render action: 'edit'
      end
    end
  end
  
    
  protected
  
  def pledge_params
    params.require(:pledge).permit(:item_id, :item_type, :pledge, :user_id, :comment)
  end
  
end
