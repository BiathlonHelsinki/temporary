class HomeController < ApplicationController
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  
  def index
    @feed = Post.not_sticky.published.order(published_at: :desc)
    @sticky = Post.sticky.published.order(published_at: :desc)
    @open_day = Event.friendly.find('open-days').instances.published.current.first rescue nil
    if @open_day.nil? 
      @open_day = Event.friendly.find('open-days').instances.published.future.order(:start_at).first
    end
    @feed += Instance.published.current.not_open_day.not_cancelled.or(Instance.published.future.not_cancelled.not_open_day).order(:start_at).to_a.delete_if{|x| !x.show_on_website?}
    # @next_other = Event
    # @feed += Proposal.active.order(created_at: :desc).to_a.delete_if{|x| x.scheduled? }
    @feed += Proposal.active.includes([:instances, :pledges]).order(updated_at: :desc).to_a.delete_if{|x| x.has_enough? }
    announcements =  Email.published.order(sent_at: :desc).limit(2)
    announcements.each do |a|
      a.body = ERB.new(a.body).result(binding).html_safe
      @feed << a
    end
    @feed += Comment.frontpage
    @current_rate = Rate.get_current.experiment_cost
    
    cal = Event.where(nil)
    cal = Event.published.between(params['start'], params['end']) if (params['start'] && params['end'])
    @calendar = []
    @calendar += cal.map(&:instances).flatten
    @calendar += Instance.published.not_cancelled.between(params['start'], params['end']) if (params['start'] && params['end'])
    @calendar.uniq!
    @calendar.flatten!
    @feed.sort_by!(&:feed_date).reverse!
  end
  
end