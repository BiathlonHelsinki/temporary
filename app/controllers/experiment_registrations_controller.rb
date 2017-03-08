class ExperimentRegistrationsController < ApplicationController
  before_action :authenticate_user!
  
  def create
    if params[:experiment_id]
      @experiment = Experiment.friendly.find(params[:experiment_id])
      @instance = @experiment.instances.friendly.find(params[:instance_id])
      r = Registration.new(instance: @instance, user: current_user)
      if r.update_attributes(params[:registration].permit!)
        if @instance.max_attendees - @instance.registrations.not_waiting.size < 1
          r.waiting_list = true
          r.save
        end
        flash[:notice] = ' Thank you for registering.'
      else
        flash[:error] = 'There was an error registering: ' + r.errors.inspect
      end
      Activity.create(user: current_user, addition: 0, item: @instance, description: 'registered for')
      redirect_to [@experiment, @instance]
    else
      flash[:error] = 'Error'
      redirect_to '/'
    end
  end
  
end