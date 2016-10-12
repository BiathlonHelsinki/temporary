class ExperimentsController < ApplicationController

  def calendar
    experiments = Experiment.where(nil)
    experiments = Experiment.published.between(params['start'], params['end']) if (params['start'] && params['end'])
    @experiments = []
    @experiments += experiments.map(&:instances).flatten
    @experiments += Instance.published.between(params['start'], params['end']) if (params['start'] && params['end'])
    @experiments.uniq!
    @experiments.flatten!
    # @experiments += experiments.reject{|x| !x.one_day? }
    set_meta_tags title: 'Calendar'
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @experiments }
    end
  end
  
  def hierarchy
    # @experiments = Experiment.roots.order(sequence: :asc)
#     respond_to do |format|
#       format.json
#     end
    render json: {name: "0 : Biathlon ", children: [name: "1 : Temporary" , children:  Experiment.collection_to_json ] }
  end
  
  def index
    
    # @experiments = Instance.future.published.order(sequence: :asc).group_by(&:experiment)
    @experiments = Instance.current.or(Instance.future).order(:start_at).uniq
    @past = Instance.past.published.order(start_at: :desc).uniq
    set_meta_tags title: 'Experiments'
  end
  
  def radial
    
  end
  
  def show
    @experiment = Experiment.friendly.find(params[:id])
    set_meta_tags title: @experiment.name
  end
  
  def tree
    @experiments = Experiment.published.order(sequence: :asc).to_json
  end

end
    