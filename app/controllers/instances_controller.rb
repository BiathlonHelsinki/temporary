class InstancesController < ApplicationController
  include ActionView::Helpers::SanitizeHelper
  before_action :authenticate_user!, only: [:rsvp]

  def cancel_registration
    if params[:experiment_id]
      @experiment = Experiment.friendly.find(params[:experiment_id])
      @instance = @experiment.instances.friendly.find(params[:id])
      if @instance.in_future?
        registration = Registration.find_or_create_by(instance: @instance, user: current_user)
        if registration.destroy
          Activity.create(user: current_user, addition: 0, item: @instance, description: 'is no longer registered for ')
          flash[:notice] = 'Thank you for letting us know, we are sorry you cannot make it.'
          redirect_to [@experiment, @instance]
        end
      end
    else
      flash[:error] = 'Error'
      redirect_to '/'
    end
  end
  
  def cancel_rsvp
    if params[:experiment_id]
      @experiment = Experiment.friendly.find(params[:experiment_id])
      @instance = @experiment.instances.friendly.find(params[:id])
      if @instance.in_future?
        rsvp = Rsvp.find_or_create_by(instance: @instance, user: current_user)
        if rsvp.destroy
          Activity.create(user: current_user, addition: 0, item: @instance, description: 'is no longer planning to attend')
          flash[:notice] = 'Thank you for letting us know, we are sorry you cannot make it.'
          redirect_to [@experiment, @instance]
        end
      end
    else
      flash[:error] = 'Error'
      redirect_to '/'
    end
  end
    
  def rsvp
    if params[:experiment_id]
      @experiment = Experiment.friendly.find(params[:experiment_id])
      @instance = @experiment.instances.friendly.find(params[:id])
      Rsvp.find_or_create_by(instance: @instance, user: current_user)
      Activity.create(user: current_user, addition: 0, item: @instance, description: 'plans to attend')
      flash[:notice] = 'Thank you for RSVPing!'
      redirect_to [@experiment, @instance]
    else
      flash[:error] = 'Error'
      redirect_to '/'
    end
  end

  def stats
    if params[:experiment_id]
      @experiment = Experiment.friendly.find(params[:experiment_id])
      @instance = @experiment.instances.friendly.find(params[:id])
      if @experiment.slug == 'open-time' && @instance.name =~ /open time/i
        if params['start'] && params['end']
          @sessions = Opensession.between(params['start'], params['end'])
          @sessions = @sessions.to_a.delete_if{|x| x.seconds_open < 90 }
        else
          @sessions = Opensession.between(@instance.start_at, @instance.end_at)
          if @temporary_is_open == true && Time.current.localtime <= @instance.end_at
            current = Opensession.by_node(1).find_by(closed_at: nil )
          end
          @sessions = @sessions.sort_by{|x| x.id }
          @potential_minutes = ((Time.current - @instance.start_at) / 60).to_i
        end
      else
        flash[:notice] = 'No statistics available for regular experiments.'
        redirect_to experiment_instance_path(@experiment, @instance)
      end
    end
    set_meta_tags title: 'Stats'
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @sessions }
    end
  end
    
  def show
    if params[:experiment_id]
      @experiment = Experiment.friendly.find(params[:experiment_id])
      @instance = @experiment.instances.friendly.find(params[:id])
      if @instance.slug == @experiment.slug && @experiment.instances.published.size == 1
        redirect_to experiment_path(@experiment.slug)
      end
      set_meta_tags title: @instance.name
      if params[:format] == 'ics'
        require 'icalendar/tzinfo'
        @cal = Icalendar::Calendar.new
        @cal.prodid = '-//Temporary, Helsinki//NONSGML ExportToCalendar//EN'

        tzid = "Europe/Helsinki"
        @cal.event do |e|
          e.dtstart     = Icalendar::Values::DateTime.new(@instance.start_at, 'tzid' => tzid)
          e.dtend       = Icalendar::Values::DateTime.new(@instance.end_at, 'tzid' => tzid)
          e.summary     = @instance.name
          e.location  = 'Temporary, Kolmas linja 7, Helsinki'
          e.description = strip_tags @instance.description
          e.ip_class = 'PUBLIC'
          e.url = e.uid = 'https://temporary.fi/experiments/' + @instance.experiment.slug + '/' + @instance.slug
        end
        @cal.publish
      end
      respond_to do |format|
        format.html # index.html.erb
        format.ics { send_data @cal.to_ical, type: 'text/calendar', disposition: 'attachment', filename: @instance.slug + ".ics" }
      end
    end
    
  end
  
  def index
    if params[:experiment_id]
      @experiment = Experiment.friendly.find(params[:experiment_id])
      redirect_to action: action_name, experiment_id: @experiment.friendly_id, status: 301 unless @experiment.friendly_id == params[:experiment_id]
      @future = @experiment.instances.current.or(@experiment.instances.future).order(:start_at).uniq
      @past = @experiment.instances.past.order(:start_at).uniq.reverse
    
    end
    set_meta_tags title: @experiment.name
    @instance = @experiment.instances.published.first
    if @experiment.instances.published.size == 1
       render template: 'instances/show'
    end
  end
  
end