class EmailsMailer < ActionMailer::Base
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  default from: "admin@temporary.fi"
  
  def announcement(user, announcement, body)
    @user = user
    @announcement = announcement
    @body = body

    mail(
      to: @user.email, 
      subject: @announcement.subject
    )
  end
end
