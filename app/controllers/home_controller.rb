class HomeController < ApplicationController
  
  def index
    @news = Post.published.order(published_at: :desc)
    @open_day = Experiment.friendly.find('open-days').instances.current.first rescue nil
    if @open_day.nil? 
      @open_day = Experiment.friendly.find('open-days').instances.future.order(:start_at).first
    end
    # @next_other = Experiment
    @recent_proposals = Proposal.all.order(created_at: :desc).to_a.delete_if{|x| x.scheduled? }
    @current_rate = Rate.get_current.experiment_cost
  end
  
end