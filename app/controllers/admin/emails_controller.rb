class Admin::EmailsController < Admin::BaseController
  
  def create
    @email = Email.new(email_params)
    if @email.save!
      flash[:notice] = 'Email draft saved.'
      redirect_to admin_emails_path
    end
  end
  
  def edit
    @email = Email.friendly.find(params[:id])
  end
  
  def new
    @email = Email.new
  end
  
  def index
    @emails = Email.all.order(:sent_at)
  end
  
  def update
    @email = Email.friendly.find(params[:id])
    if @email.update_attributes(email_params)
      flash[:notice] = 'Email draft updated.'
      redirect_to admin_emails_path
    end
  end
  
  private
  
  def email_params
    params.require(:email).permit(:subject, :body)
  end
  
end