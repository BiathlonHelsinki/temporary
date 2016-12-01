class EmailsMailer < ActionMailer::Base
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  default from: "Temporary Helsinki <admin@temporary.fi>"
  
  def announcement(user, announcement, body)
    @user = user
    @announcement = announcement
    @body = body
    headers['List-Unsubscribe'] = '<mailto:admin@temporary.fi>'
    mail(to: @user.email, subject: @announcement.subject)  do |format|
      format.html
      format.text
    end
  end
  
  def test(email, announcement, body)

    @announcement = announcement
    @body = body
    headers['List-Unsubscribe'] = '<mailto:admin@temporary.fi>'
    mail(to: email, subject: @announcement.subject)  do |format|
      format.html
      format.text
    end
  end
  
end
