class ActivitiesController < ApplicationController
  
  def index
    if params[:user_id]
      @user = User.friendly.find(params[:user_id])
      @activities = Activity.by_user(@user.id).order(created_at: :desc)
    else
      @activities = Activity.order(created_at: :desc)
    end
  end
  
end