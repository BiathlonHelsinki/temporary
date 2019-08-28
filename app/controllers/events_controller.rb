class EventsController < ApplicationController
  include ActionView::Helpers::SanitizeHelper
  
  def archive
    @past = Instance.includes([:translations, :users, :onetimers]).past.published.order(start_at: :desc).uniq
    set_meta_tags title: 'Event archive'
  end

  def redirect_event
    redirect_to "/experiments/" + params[:id] and return
  end
  
  def calendar
    experiments = Event.none
    experiments = Event.published.between(params['start'], params['end']) if (params['start'] && params['end'])
    @experiments = []
    @experiments += experiments.map{|x| x.instances.published}.flatten
    @experiments += Instance.published.between(params['start'], params['end']) if (params['start'] && params['end'])
    @experiments.uniq!
    @experiments.flatten!
    # @experiments += experiments.reject{|x| !x.one_day? }
    if params[:format] == 'ics'
      require 'icalendar/tzinfo'
      @cal = Icalendar::Calendar.new
      @cal.prodid = '-//Temporary, Helsinki//NONSGML ExportToCalendar//EN'

      tzid = "Europe/Helsinki"
      tz = TZInfo::Timezone.get tzid
      @experiments.delete_if{|x| x.cancelled == true }.each do |event|
      
        @cal.event do |e|
          e.dtstart     = Icalendar::Values::DateTime.new(event.start_at, 'tzid' => tzid)
          e.dtend       = Icalendar::Values::DateTime.new(event.end_at, 'tzid' => tzid)
          e.summary     = event.name
          e.location  = 'Temporary, Kolmas linja 7, Helsinki'
          e.description = strip_tags event.description
          e.ip_class = 'PUBLIC'
          e.url = e.uid = 'https://temporary.fi/experiments/' + event.event.slug + '/' + event.slug
        end
      end
      @cal.publish
    end
    set_meta_tags title: 'Calendar'
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @experiments }
      format.ics { render :text => @cal.to_ical }
    end
  end
  
  
  def hierarchy
    # @experiments = Event.roots.order(sequence: :asc)
#     respond_to do |format|
#       format.json
#     end
    render json: {name: "0 : Biathlon ", children: [name: "1 : Temporary" , children:  Event.collection_to_json ] }
  end
  
  def index
    # @experiments = Instance.future.published.order(sequence: :asc).group_by(&:experiment)
    @experiments = Instance.includes(:translations).where(place_id: 1).current.published.or(Instance.future.published.includes(:translations)).order(:start_at).uniq
    @past = Instance.includes([:translations, :users, :onetimers]).where(place_id: 1).past.published.order(start_at: :desc).limit(8).uniq
    set_meta_tags title: 'Events'
  end

  def radial
   
  end
 
  def show
    @experiment = Event.friendly.find(params[:id])
    set_meta_tags title: @experiment.name
  end
 
  def tree
    @experiments = Event.published.order(sequence: :asc).to_json
  end
 
  private

  def set_item
    @experiment = Event.friendly.find(params[:id])
    redirect_to action: action_name, id: @experiment.friendly_id, status: 301 unless @experiment.friendly_id == params[:id]
  end
end
    