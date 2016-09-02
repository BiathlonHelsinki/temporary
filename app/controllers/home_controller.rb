class HomeController < ApplicationController
  
  def index
    @news = Post.published.order(published_at: :desc)
    @open_day = Experiment.friendly.find('open-days').instances.future.first
    # @next_other = Experiment
    @recent_proposals = Proposal.all.order(created_at: :desc).to_a.delete_if{|x| x.scheduled? }
  end
  
end