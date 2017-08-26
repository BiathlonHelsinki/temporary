class Admin::SurveysController < Admin::BaseController
  skip_load_and_authorize_resource
  load_and_authorize_resource
  
  def index
    @surveys = Survey.all
  end
  
  def show
    @survey = Survey.find(params[:id])
  end
  
  def destroy
    @survey = Survey.find(params[:id])
    if @survey.destroy
      flash[:notice] = "Survey deleted."
      redirect_to admin_surveys_path
    end
  end
end