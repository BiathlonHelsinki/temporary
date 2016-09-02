class HomeController < ApplicationController
  
  def index
    @news = Post.published.order(published_at: :desc)
    @open_day = Experiment.friendly.find('open-days').instances.future.first
    # @next_other = Experiment
    @recent_proposal = Proposal.order(created_at: :desc).first
  end
  
end