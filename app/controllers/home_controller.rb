class HomeController < ApplicationController
  
  def index
    @news = Post.not_sticky.published.order(published_at: :desc)
    @sticky = Post.sticky.published.order(published_at: :desc)
    @open_day = Experiment.friendly.find('open-days').instances.published.current.first rescue nil
    if @open_day.nil? 
      @open_day = Experiment.friendly.find('open-days').instances.published.future.order(:start_at).first
    end
    @upcoming = Instance.published.current.not_open_day.or(Instance.published.future.not_open_day).order(:start_at).to_a.delete_if{|x| !x.show_on_website?}
    # @next_other = Experiment
    @recent_proposals = Proposal.all.order(created_at: :desc).to_a.delete_if{|x| x.scheduled? }
    @current_rate = Rate.get_current.experiment_cost
    
    cal = Experiment.where(nil)
    cal = Experiment.published.between(params['start'], params['end']) if (params['start'] && params['end'])
    @calendar = []
    @calendar += cal.map(&:instances).flatten
    @calendar += Instance.published.between(params['start'], params['end']) if (params['start'] && params['end'])
    @calendar.uniq!
    @calendar.flatten!
  end
  
end