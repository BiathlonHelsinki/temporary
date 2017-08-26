class SurveysController < ApplicationController
  
  before_action :authenticate_user!
  
  
  def create
    @survey = Survey.new(survey_params)
    if params[:commit]
      @survey.completed = true
    elsif params[:save]
      @survey.completed = false
    end
    if @survey.save
      flash[:notice] = @survey.completed == true ? t(:thanks_for_survey) : t(:answers_were_saved)
      redirect_to '/'
    end
  end
  
  def new
    if current_user.survey.nil?
      @survey = Survey.new
    else
      @survey = current_user.survey
    end
  end
  
  
  def index
    redirect_to new_survey_path
  end
  
  
  def update
    @survey = Survey.find(params[:id])
 
    if params[:commit]
      @survey.completed = true
    elsif params[:save]
      @survey.completed = false
    end
    if @survey.update_attributes(survey_params)
      flash[:notice] = @survey.completed == true ? t(:thanks_for_survey) : t(:answers_were_saved)
      redirect_to '/'
    end
  end
  
  protected
  
  def survey_params
    params.require(:survey).permit(:user_id, :never_visited, :experiment_why, :platform_benefits, :different_contribution, :welcoming_concept, :physical_environment, :website_etc, :different_than_others, :your_space, :allow_excerpt, :allow_identity, :features_benefit, :improvements, :clear_structure, :want_from_culture)
    
  end\
  
end