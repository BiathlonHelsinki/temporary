class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@temporary.fi'
  layout 'mailer'
end
