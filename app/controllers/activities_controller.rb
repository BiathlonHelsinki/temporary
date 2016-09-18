class ActivitiesController < ApplicationController
  
  def index
    if params[:user_id]
      @user = User.friendly.find(params[:user_id])
      @activities = Activity.by_user(@user.id).order(created_at: :desc).page(params[:page]).per(40)
    else
      @activities = Activity.all.order(created_at: :desc).page(params[:page]).per(40)
    end
  end
  
end