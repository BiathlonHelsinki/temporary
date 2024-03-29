class ProposalsController < ApplicationController
  before_action :authenticate_user!, only: %i[new create edit update destroy]
  caches_page :archive, :show, :index
  def archived
    # @needs_support_count = Proposal.active.to_a.delete_if{|x| x.has_enough_cached == true }.size
    @scheduled_count = Instance.future.or(Instance.current).map(&:proposal).uniq.size
    @review_count = Proposal.active.schedulable.delete_if { |x| !x.instances.current.or(x.instances.future).empty? }.count

    @next_meeting = Instance.next_meeting
    @current_rate = Rate.get_current.experiment_cost
    @proposals = Proposal.includes([:user, :proposalstatus, { comments: [:user], instances: %i[event translations pledges], pledges: [:user] }]).archived.order(updated_at: :desc).page(params[:page]).per(10)
    set_meta_tags(title: 'Archived proposals')
    # render text: 'the error is in the template'
    render(template: 'proposals/index')
  end

  def create
    current_user.update_balance_from_blockchain if @api_status
    @proposal = Proposal.new(proposal_params)
    if @proposal.save
      flash[:notice] = 'Your proposal has been submitted! Now, you can pledge some of your Temps to it.'
      redirect_to(proposals_path)
    else
      flash[:error] = 'There was an error saving your proposal'
    end
  end

  def destroy
    @proposal = Proposal.find(params[:id])
    if @proposal.user != current_user && !current_user.has_role?(:admin)
      flash[:error] = "You cannot delete someone else's proposal."
      redirect_to(@proposal)
    else
      @proposal.destroy
      flash[:notice] = 'Your proposal was deleted.'
      redirect_to(proposals_path)
    end
  end

  def edit
    @proposal = Proposal.find(params[:id])
    current_user.update_balance_from_blockchain if @api_status
    @current_rate = Rate.get_current.experiment_cost
    if @proposal.user != current_user && !current_user.has_role?(:admin)
      flash[:error] = "You cannot edit someone else's proposal."
      redirect_to(@proposal)
    end
    set_meta_tags(title: 'Edit proposal')
  end

  def index
    if params[:filter].nil? || params[:filter] == 'false'
      @proposals = Proposal.active.still_in_proposal_form.includes([:user, :proposalstatus, { comments: [:user], instances: %i[event translations pledges], pledges: [:user] }]).order(updated_at: :desc) #.sort_by { |x| (x.has_enough? ? (x.recurs? ? (x.intended_sessions == 0 && (x.pledged < x.total_needed_with_recurrence) ? 2 : 1 ) : 4 ) :         (x.instances.empty? ? 0 : 1) ) }
    # elsif params[:filter] == 'needs_support'
#       @proposals = Proposal.active.still_in_proposal_form.includes([:instances, :pledges]).order(updated_at: :desc).to_a.delete_if{|x| x.has_enough? } #.sort_by { |x| (x.has_enough? ? (x.recurs? ? (x.intended_sessions == 0 && (x.pledged < x.total_needed_with_recurrence) ? 2 : 1 ) : 4 ) :      (x.instances.empty? ? 0 : 1) ) }
    elsif params[:filter] == 'scheduled'
      @proposals = Instance.includes(:translations).future.or(Instance.includes([:translations]).current).map(&:proposal).uniq.sort_by { |x| x.updated_at }.reverse # x.next_instance.start_at }
    elsif params[:filter] == 'review'
      @proposals = #to_a.delete_if{|x| !x.has_enough? }.delete_if{|x| !x.instances.published.future.empty? }
        Proposal.still_in_proposal_form.includes([:user, :proposalstatus, { comments: [:user], instances: %i[event translations pledges], pledges: [:user] }]).active.schedulable.sort_by(&:updated_at).reverse.to_a.delete_if do |x|
          !x.instances.current.or(x.instances.future).empty?
        end
    end

    @next_meeting = Instance.includes(:event, :pledges).next_meeting
    @current_rate = Rate.get_current.experiment_cost

    # @needs_support_count = Proposal.still_in_proposal_form.active.to_a.delete_if{|x| x.has_enough_cached == true }.size
    @scheduled_count = Instance.future.includes(:proposal).or(Instance.current.includes(:proposal)).map(&:proposal).uniq.size
    @review_count = Proposal.still_in_proposal_form.active.schedulable.delete_if { |x| !x.instances.current.or(x.instances.future).empty? }.count #to_a.delete_if{|x| !x.has_enough? }.delete_if{|x| !x.instances.published.empty? }.size

    set_meta_tags(title: t(:proposals))
  end

  def new
    if current_user.email =~ /change@me/
      flash[:error] = 'You must enter a valid email address in order to propose an event.'
      redirect_to(proposals_path)
    else
      current_user.update_balance_from_blockchain if @api_status
      @current_rate = Rate.get_current.experiment_cost
      @proposal = Proposal.new(user: current_user)
    end
    set_meta_tags(title: 'New proposal')
  end

  def search
    @needs_support_count = Proposal.active.to_a.delete_if { |x| x.has_enough_cached == true }.size
    @scheduled_count = Instance.future.or(Instance.current).map(&:proposal).uniq.size
    @review_count = Proposal.active.to_a.delete_if { |x| x.has_enough_cached == false }.delete_if { |x| !x.instances.published.empty? }.size

    @next_meeting = Instance.next_meeting
    @current_rate = Rate.get_current.experiment_cost
    @proposals = Proposal.search_all_text(params[:by_string])
    render(template: 'proposals/index')
  end

  def original_proposal
    @proposal = Proposal.find(params[:id])
    set_meta_tags(title: @proposal.name)
    if @proposal.still_proposal?
      redirect_to(@proposal)
    else
      render(template: 'proposals/show')
    end
  end

  def show
    @current_rate = Rate.get_current.experiment_cost
    @next_meeting = Instance.next_meeting
    begin
      @proposal = Proposal.find(params[:id])
      redirect_to(@proposal.instances.first.event) unless @proposal.still_proposal?
      set_meta_tags(title: @proposal.name)
    rescue ActiveRecord::RecordNotFound
      @idea = Idea.friendly.find(params[:id])
      redirect_to("https://kuusipalaa.fi/ideas/#{@idea.slug}")
    end
  end

  def update
    @proposal = Proposal.find(params[:id])
    if @proposal.user != current_user && !current_user.has_role?(:admin)
      flash[:error] = "You cannot edit someone else's proposal."
      redirect_to(@proposal)
    elsif @proposal.update_attributes(proposal_params)
      flash[:notice] = 'Your proposal has been edited!'
      redirect_to(proposals_path)
    else
      flash[:error] = 'There was an error saving your edited proposal.'
    end
  end

  protected

  def proposal_params
    params.require(:proposal).permit(:user_id, :name, :recurrence, :intended_sessions, :stopped, :short_description, :timeframe, :goals, :intended_participants, :require_all,
                                     images_attributes: %i[image _destroy proposal_id id remove_image])
  end
end
