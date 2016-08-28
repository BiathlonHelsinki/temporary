class PledgesController < ApplicationController

  before_filter :authenticate_user!
  
  
  def create
    current_user.update_balance_from_blockchain
    balance = current_user.latest_balance
    @proposal = Proposal.find(params[:proposal_id])
    
    if balance < params[:pledge][:pledge].to_i
      flash[:error] = 'You do not have this many ' + ENV['currency_full_name']
      redirect_to new_proposal_pledge_path(@proposal)
    else
      @pledge = Pledge.new(pledge_params)
      @pledge.item = @proposal
      @pledge.user = current_user
      if @pledge.save
        render template: 'pledges/after_pledge'
      else
        flash[:error] = 'There was an error saving your pledge: ' + @pledge.errors.inspect
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
    @current_rate = Rate.get_current.experiment_cost
    @item = Proposal.find(params[:proposal_id])
    @pledge = @item.pledges.find(params[:id])
    
  end
  
  def new
    @current_rate = Rate.get_current.experiment_cost
    @item = Proposal.find(params[:proposal_id])
    @pledge = @item.pledges.build
  end
  
  
  def update
    @item = Proposal.find(params[:proposal_id])
    @pledge = @item.pledges.find(params[:id])
    if @pledge.update_attributes(pledge_params)
      flash[:notice] = 'Your pledge has been edited!'
      redirect_to @item
    else
      flash[:error] = 'There was an error saving your edited pledge.'
      render action: 'edit'
    end
  end
  
    
  protected
  
  def pledge_params
    params.require(:pledge).permit(:item_id, :item_type, :pledge, :user_id, :comment)
  end
  
end
