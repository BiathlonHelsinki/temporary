class Admin::EmailsController < Admin::BaseController
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  
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
  
  def send_test
    @email = Email.friendly.find(params[:id])
    @user = User.find(1)
    body = ERB.new(@email.body).result(binding).html_safe
    EmailsMailer.announcement(@user, @email, body).deliver_now
    flash[:notice] = 'Email sent to ' + @user.email
    redirect_to admin_emails_path
  end
  
  def send_to_list
    @email = Email.friendly.find(params[:id])
    if @email.sent == true
      flash[:notice] = 'Email already sent'
      redirect_to admin_emails_path
    else
      mailing_list = User.where(opt_in: true).where("email not like 'change@me%'")
      if Rails.env.development?
        mailing_list[3..7].each do |recipient|
          @user = recipient
          body = ERB.new(@email.body).result(binding).html_safe
          EmailsMailer.announcement(recipient, @email, body).deliver_later
        end
      else
        mailing_list.each do |recipient|
          @user = recipient
          body = ERB.new(@email.body).result(binding).html_safe
          EmailsMailer.announcement(recipient, @email, body).deliver_later
        end
        @email.sent = true
        @email.save
      end
      flash[:notice] = 'Sending emails to ' + mailing_list.size.to_s + " users"
      @email.sent_number = mailing_list.size
      @email.sent_at = Time.current
      @email.save
      redirect_to admin_emails_path
    end
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