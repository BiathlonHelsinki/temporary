class Admin::InstancesController < Admin::BaseController
  
  def create
    api = BiathlonApi.new

    if params[:instance] && params[:instance][:image]
      # data = StringIO.new(Base64.decode64(File.new(params[:instance][:attachment].tempfile)))
      # data.class.class_eval { attr_accessor :original_filename, :content_type }
      # data.original_filename = params[:instance][:attachment][:filename]
      # data.content_type = params[:instance][:attachment][:content_type]
      params[:instance][:image] = Base64.encode64(params[:instance][:image].tempfile.read)
    end

    success = api.api_post("/instances", {user_email: current_user.email, 
                            user_token: current_user.authentication_token, instance: params[:instance].to_hash})
    if success['error']
      logger.warn('error is ' + success['error'].inspect)
      flash[:error] = success['error']
      
      @experiment = Event.friendly.find(params[:event_id])
      @instance = Instance.new(instance_params)
      @instance.event = @experiment
      render template: 'admin/instances/new'
    else
      if params[:instance][:send_to_pledgers] == '1' 
        @instance = Instance.friendly.find(success['data']['id'])
        if @instance.published == true
          @instance.pledges.each do |pledge|
            next if pledge.user.opt_in != true
            InstancesMailer.pledge_was_scheduled(@instance.proposal, pledge.user).deliver_later
          end
        end
      end
      
      # send scheduling notifications
      unless @instance.event.notifications.empty?
        @instance.event.notifications.each do |n|
          next unless n.scheduling == true
          NotificationMailer.new_scheduling(@instance, n.user).deliver_later
        end
      end
      
      flash[:notice] = 'Your instance was accepted, thank you!'
      redirect_to admin_events_path
    end                        
  end


  def edit
    @instance = Instance.friendly.find(params[:id])
    @experiment = @instance.event
  end
  
  def new
    @experiment = Event.friendly.find(params[:event_id])
    @proposal = @experiment.instances.sort_by(&:sequence).last.proposal
    @instance = Instance.new(event: @experiment, cost_bb: @experiment.cost_bb, 
                              sequence: @experiment.instances.blank? ? @experiment.sequence + ".1" :
                              @experiment.instances.sort_by{|x| x.sequence.rpartition(/\./).last.to_i }.last.sequence.rpartition(/\./).first + "." + (@experiment.instances.sort_by{|x| x.sequence.rpartition(/\./).last.to_i}.last.sequence.rpartition(/\./).last.to_i + 1).to_s,
                              
                               cost_euros: @experiment.cost_euros, 
                              start_at: @experiment.start_at, end_at: @experiment.end_at,
                              place_id: @experiment.place_id, published: @experiment.published, 
                              translations_attributes: [{locale: 'en', name: @experiment.name(:en), 
                                              description: @experiment.description(:en)}])
    if @proposal.remaining_pledges < @instance.cost_in_temps
      flash[:warning] = 'Warning: There are not enough Temps pledged to this proposal to schedule another instance. Doing so anyway requires taking from a different proposal so only do this if you have a damn good reason.'
    end
  end
  
  def destroy
    api = BiathlonApi.new
    success = api.api_delete("/instances/#{params[:id]}", {user_email: current_user.email, 
                            user_token: current_user.authentication_token}) 
    if success['error']
      flash[:error] = success['error']
    else                           
      flash[:notice] = 'The instance was deleted, thank you!'
    end
    redirect_to admin_events_path

  end                            

 

  def update
    api = BiathlonApi.new

    if params[:instance] && params[:instance][:image]
      # data = StringIO.new(Base64.decode64(File.new(params[:instance][:attachment].tempfile)))
      # data.class.class_eval { attr_accessor :original_filename, :content_type }
      # data.original_filename = params[:instance][:attachment][:filename]
      # data.content_type = params[:instance][:attachment][:content_type]
      params[:instance][:image] = Base64.encode64(params[:instance][:image].tempfile.read)
    end

    success = api.api_put("/instances/#{params[:id]}", {user_email: current_user.email, 
                            user_token: current_user.authentication_token, instance: params[:instance].to_hash})
    if success['error']
      logger.warn('error is ' + success['error'].inspect)
      flash[:error] = success['error']
      
      @experiment = Event.friendly.find(params[:event_id])
      @instance = Instance.friendly.find(params[:id])
      @instance.event = @experiment
      render template: 'admin/instances/edit'
    else
      if params[:instance][:send_to_pledgers] == '1' 
        @instance = Instance.friendly.find(params[:id])
        if @instance.published == true
          @instance.pledges.each do |pledge|
            next if pledge.user.opt_in != true
            InstancesMailer.pledge_was_scheduled(@instance.proposal, pledge.user).deliver_now
          end
        end
      end
      flash[:notice] = 'Your instance was accepted, thank you!'
      redirect_to admin_events_path
    end                        
  end
    
  
  
  private
  
  def instance_params
    params.require(:instance).permit(:published, :event_id, :place_id, :primary_sponsor_id, :is_meeting, :proposal_id, :cancelled, :survey_locked,
    :secondary_sponsor_id, :cost_euros, :cost_bb, :sequence, :start_at, :end_at, :sequence, :allow_multiple_entry, 
    :request_rsvp, :request_registration, :custom_bb_fee, :email_registrations_to, :question1_text, :question2_text,
    :question3_text, :question4_text, :boolean1_text, :boolean2_text, :require_approval, :hide_registrants,
    :show_guests_to_public, :max_attendees, :registration_open,
    :parent_id, :image, events_attributes: [:secondary_sponsor], organiser_ids: [], translations_attributes: [:name, :description, :instance_id, :locale, :id]
    )
  end
  
end